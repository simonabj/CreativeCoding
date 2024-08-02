from GladosVoice import speak
from tools.ResponseParser import ResponseParser
import anthropic

LLM_MODEL = "claude-3-5-sonnet-20240620"
MAX_TOKENS = 1000
TEMPERATURE = 1

SYSTEM_PRIMER = "".join(open("glados-primer.txt", "r").readlines())

glados_llm = anthropic.Anthropic()

response_parser = ResponseParser()

recent_thoughts = []

def get_recent_thoughts():
    return "\n".join(recent_thoughts)

while True:
    prompt = input("Input: ")
        
    response = glados_llm.messages.create(
        model=LLM_MODEL,
        max_tokens=MAX_TOKENS,
        temperature=TEMPERATURE,
        system=SYSTEM_PRIMER,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"<memory>{get_recent_thoughts()}</memory> {prompt}"
                    }
                ]
            }
        ]
    )

    content = response_parser.parse(next(
        (block.text for block in response.content if hasattr(block, "text")),
        None,
    ))

    print(content)

    speak(content["speak"])
    
    recent_thoughts += content["thinking"].split("\n")
    recent_thoughts = recent_thoughts[-5:]

    print(recent_thoughts)
    
    print("Memorizing:")
    for entry in content["memory"]:
        print(f"- {entry}")