"""Thin LLM client wrapper — routes to Bedrock Mantle (unified OpenAI-compatible),
direct Anthropic, or direct OpenAI depending on environment.

When OPENAI_BASE_URL points to bedrock-mantle, ALL models (OpenAI and Anthropic)
are routed through the OpenAI-compatible endpoint.  Otherwise, OpenAI models go
through the OpenAI SDK and Anthropic models go through the Anthropic SDK.

Usage:
    client = LLMClient.from_model(model, openai_key=..., anthropic_key=...)
    resp = client.messages.create(model=model, max_tokens=4000,
                                  system="...", messages=[...])
    text = resp.content[0].text
    print(resp.usage)  # _Usage(input_tokens=..., output_tokens=...)
    print(client.total_input_tokens, client.total_output_tokens)
"""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass, field
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

_OPENAI_PREFIXES = (
    "gpt-", "o1", "o1-", "o3", "o3-", "o4-", "gpt-5",
    "gpt-oss-", "text-davinci", "openai.",
)

_MANTLE_MODEL_MAP = {
    "gpt-5.5": "openai.gpt-5.5",
    "gpt-5.4": "openai.gpt-5.4",
    "claude-opus-4-8": "anthropic.claude-opus-4-8",
    "claude-opus-4-7": "anthropic.claude-opus-4-7",
    "claude-haiku-4-5": "anthropic.claude-haiku-4-5",
    "claude-sonnet-4-6": "anthropic.claude-sonnet-4-6",
    "claude-opus-4-6": "anthropic.claude-opus-4-6",
}

_BEDROCK_MODEL_MAP = {
    "claude-opus-4-6": "us.anthropic.claude-opus-4-6-v1",
    "claude-sonnet-4-6": "us.anthropic.claude-sonnet-4-6",
    "claude-haiku-4-5-20251001": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
}


def _is_mantle() -> bool:
    return "bedrock-mantle" in os.environ.get("OPENAI_BASE_URL", "")


def _is_openai_model(model: str) -> bool:
    m = model.lower()
    return any(m == p.rstrip("-") or m.startswith(p) for p in _OPENAI_PREFIXES)


def _is_reasoning_model(model: str) -> bool:
    m = model.lower().replace("openai.", "")
    return m.startswith(("o1", "o3", "o4", "gpt-5"))


def _mantle_model_id(model: str) -> str:
    if model in _MANTLE_MODEL_MAP:
        return _MANTLE_MODEL_MAP[model]
    if "." in model:
        return model
    if _is_openai_model(model):
        return f"openai.{model}"
    return f"anthropic.{model}"


def _bedrock_model_id(model: str) -> str:
    if model in _BEDROCK_MODEL_MAP:
        return _BEDROCK_MODEL_MAP[model]
    if model.startswith("us.anthropic.") or model.startswith("anthropic."):
        return model
    for short, full in _BEDROCK_MODEL_MAP.items():
        if short in model:
            return full
    return f"us.anthropic.{model}-v1:0"


@dataclass
class _Content:
    text: str


@dataclass
class _Usage:
    input_tokens: int = 0
    output_tokens: int = 0


@dataclass
class _Response:
    content: List[_Content]
    usage: _Usage = field(default_factory=_Usage)


class _MessagesNamespace:
    def __init__(self, backend):
        self._backend = backend

    def create(
        self,
        *,
        model: str,
        max_tokens: int,
        system: str,
        messages: List[Dict],
        **kwargs,
    ) -> _Response:
        return self._backend(
            model=model,
            max_tokens=max_tokens,
            system=system,
            messages=messages,
            **kwargs,
        )


class LLMClient:
    """Unified LLM client — Bedrock Mantle, direct Anthropic, or direct OpenAI."""

    def __init__(
        self,
        *,
        anthropic_key: Optional[str] = None,
        openai_key: Optional[str] = None,
        use_bedrock: bool = False,
        bedrock_region: str = "us-east-1",
    ):
        self._anthropic_key = anthropic_key
        self._openai_key = openai_key
        self._use_bedrock = use_bedrock
        self._bedrock_region = bedrock_region
        self._mantle = _is_mantle()
        self._anthropic_client = None
        self._openai_client = None
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        self.messages = _MessagesNamespace(self._call)
        if self._mantle:
            logger.info("Bedrock Mantle mode (all models via OpenAI-compatible endpoint)")

    def _get_anthropic(self):
        if self._anthropic_client is None:
            import anthropic as _anthropic
            if self._use_bedrock:
                self._anthropic_client = _anthropic.AnthropicBedrock(
                    aws_region=self._bedrock_region,
                )
                logger.info("Using Anthropic via Bedrock (%s)", self._bedrock_region)
            else:
                self._anthropic_client = _anthropic.Anthropic(api_key=self._anthropic_key)
                logger.info("Using Anthropic direct API")
        return self._anthropic_client

    def _get_openai(self):
        if self._openai_client is None:
            import openai as _openai
            self._openai_client = _openai.OpenAI(api_key=self._openai_key, timeout=600.0)
        return self._openai_client

    def _call_via_openai(self, *, model: str, max_tokens: int, system: str,
                         messages: List[Dict]) -> _Response:
        formatted = [{"role": "system", "content": system}] + list(messages)
        params = {"model": model, "messages": formatted}
        if _is_reasoning_model(model):
            params["max_completion_tokens"] = max_tokens
        else:
            params["max_tokens"] = max_tokens
        resp = self._get_openai().chat.completions.create(**params)
        text = resp.choices[0].message.content or ""
        # Handle encoding artifacts from Bedrock Mantle
        text = text.encode("utf-8", errors="replace").decode("utf-8", errors="replace")
        usage = _Usage(
            input_tokens=getattr(resp.usage, "prompt_tokens", 0) or 0,
            output_tokens=getattr(resp.usage, "completion_tokens", 0) or 0,
        )
        return _Response(content=[_Content(text=text)], usage=usage)

    def _call_via_anthropic(self, *, model: str, max_tokens: int, system: str,
                            messages: List[Dict], **kwargs) -> _Response:
        bedrock_model = _bedrock_model_id(model) if self._use_bedrock else model
        resp = self._get_anthropic().messages.create(
            model=bedrock_model, max_tokens=max_tokens, system=system,
            messages=messages, **kwargs,
        )
        text = resp.content[0].text
        usage = _Usage(
            input_tokens=getattr(resp.usage, "input_tokens", 0) or 0,
            output_tokens=getattr(resp.usage, "output_tokens", 0) or 0,
        )
        return _Response(content=[_Content(text=text)], usage=usage)

    def _call(self, *, model: str, max_tokens: int, system: str,
              messages: List[Dict], **kwargs) -> _Response:
        if self._mantle:
            mantle_id = _mantle_model_id(model)
            result = self._call_via_openai(
                model=mantle_id, max_tokens=max_tokens,
                system=system, messages=messages,
            )
        elif _is_openai_model(model):
            result = self._call_via_openai(
                model=model, max_tokens=max_tokens,
                system=system, messages=messages,
            )
        else:
            result = self._call_via_anthropic(
                model=model, max_tokens=max_tokens,
                system=system, messages=messages, **kwargs,
            )

        self.total_input_tokens += result.usage.input_tokens
        self.total_output_tokens += result.usage.output_tokens
        return result

    @classmethod
    def from_model(
        cls,
        model: str,
        anthropic_key: Optional[str] = None,
        openai_key: Optional[str] = None,
    ) -> "LLMClient":
        use_bedrock = bool(os.environ.get("USE_BEDROCK"))
        bedrock_region = os.environ.get("BEDROCK_REGION", "us-east-1")
        return cls(
            anthropic_key=anthropic_key,
            openai_key=openai_key,
            use_bedrock=use_bedrock,
            bedrock_region=bedrock_region,
        )
