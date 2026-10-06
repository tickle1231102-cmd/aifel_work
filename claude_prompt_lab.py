import asyncio
import json
from pathlib import Path

from claude_agent_sdk import (
    AssistantMessage, ClaudeAgentOptions, TextBlock, query,
)

MODEL = "haiku"
COMMON = "한국어로 답한다. 배송 조회 도구와 주문 데이터는 없다. 확인하지 않은 배송일이나 도구 사용을 주장하지 않는다. "
SYSTEM_A = COMMON + "고객에게 정중한 상담 톤으로 답한다."
SYSTEM_B = COMMON + "간결한 기술 문서 톤으로 답한다."
QUESTION = "배송일은 언제인가요?"
FOLLOWUP = "아직 없어요. 그러면 무엇부터 확인하죠?"
CONTEXT = """이전 대화 요약(비교용으로 작성한 자료):
고객은 배송일을 물었고, 상담자는 주문번호 또는 운송장 번호를 확인해 달라고 안내했다.
"""

cases = [
    ("A_customer", SYSTEM_A, QUESTION),
    ("B_technical", SYSTEM_B, QUESTION),
    ("C_no_context", SYSTEM_B, FOLLOWUP),
    ("D_with_context", SYSTEM_B, CONTEXT + "\n현재 질문: " + FOLLOWUP),
]

async def main():
    records = []
    for name, system_prompt, user_input in cases:
        for trial in range(3):
            record = {
                "case": name, "trial": trial + 1, "model_alias": MODEL,
                "system_prompt": system_prompt, "user_input": user_input,
                "events": [], "answer_parts": [],
            }
            options = ClaudeAgentOptions(
                model=MODEL,
                system_prompt=system_prompt,
                tools=[],
                mcp_servers={},
                strict_mcp_config=True,
                max_turns=1,
            )
            try:
                async for event in query(prompt=user_input, options=options):
                    record["events"].append(repr(event))
                    if isinstance(event, AssistantMessage):
                        for block in event.content:
                            if isinstance(block, TextBlock):
                                record["answer_parts"].append(block.text)
            except Exception as error:
                record["error"] = f"{type(error).__name__}: {error}"
            records.append(record)
            Path("claude_lab_results.json").write_text(
                json.dumps(records, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
    print("claude_lab_results.json에 입력과 응답을 저장했습니다.")

asyncio.run(main())