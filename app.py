import os
import sqlite3
import torch
import numpy as np
import zipfile
import requests
from transformers import AutoTokenizer, AutoModel
from openai import AsyncOpenAI
import chainlit as cl

# OpenAI GPT 설정
client = AsyncOpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

settings = {
    "model": "gpt-4o",
    "temperature": 0.7,
    "max_tokens": 500,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0,
}

import os
import requests
import zipfile
from transformers import AutoTokenizer, AutoModel


# e5 모델 경로 설정
model_path = "/app/e5/multilingual-e5-small"
tokenizer = AutoTokenizer.from_pretrained(model_path)
model = AutoModel.from_pretrained(model_path)

# SQLite DB 경로
db_path = "./prugio_notice.db"

# 텍스트 임베딩 생성
def get_embedding(text: str):
    """텍스트의 임베딩을 생성합니다."""
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
        embeddings = outputs.last_hidden_state.mean(dim=1)  # Mean pooling
    return embeddings.squeeze()

# 유사도 검색 함수
def find_similar_entries(user_embedding, db_path, top_n=3, min_similarity=0.5):
    """DB에서 사용자 입력과 가장 유사한 항목을 찾습니다."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT id, content, embedding FROM recipe")

    db_embeddings = []
    contents = []
    ids = []

    for recipe_id, content, embedding in cursor.fetchall():
        if embedding is None:
            continue
        try:
            embedding_array = np.frombuffer(embedding, dtype=np.float32)
            embedding_tensor = torch.tensor(embedding_array)
            db_embeddings.append(embedding_tensor)
            contents.append(content)
            ids.append(recipe_id)
        except Exception as e:
            print(f"Error processing ID {recipe_id}: {e}")

    conn.close()

    if not db_embeddings:
        return []

    # 코사인 유사도 계산
    db_embeddings = torch.stack(db_embeddings)
    user_embedding = user_embedding.unsqueeze(0)
    scores = torch.nn.functional.cosine_similarity(user_embedding, db_embeddings)

    # 상위 N개 정렬
    top_indices = torch.argsort(scores, descending=True)[:top_n]
    results = [
        {"id": ids[i], "content": contents[i], "score": scores[i].item()}
        for i in top_indices if scores[i].item() >= min_similarity
    ]
    return results

# Chainlit 시작 시 초기화
@cl.on_chat_start
def start_chat():
    cl.user_session.set(
        "message_history",
        [{"role": "system", "content": "당신의 역할은 모집공고문을 보고 예비 입주자들에게 궁금한 점을 알려주는 도우미입니다."}],
    )

# 사용자 메시지 처리
@cl.on_message
async def main(message: cl.Message):
    user_input = message.content
    message_history = cl.user_session.get("message_history")

    # 사용자 입력 임베딩 생성
    user_embedding = get_embedding(user_input)

    # 유사도 검색 수행
    similar_entries = find_similar_entries(user_embedding, db_path)
    if similar_entries:
        context = similar_entries[0]["content"]
    else:
        context = "유사한 항목이 데이터베이스에 없습니다."

    # GPT 모델에 전달할 프롬프트 구성
    message_history.append({"role": "user", "content": user_input})
    message_history.append({"role": "system", "content": f"다음 내용을 참고하여 답변해 주세요: {context}"})

    # GPT-4o 호출 및 응답 스트리밍
    msg = cl.Message(content="")
    await msg.send()

    stream = await client.chat.completions.create(
        messages=message_history, stream=True, **settings
    )

    async for part in stream:
        if token := part.choices[0].delta.content or "":
            await msg.stream_token(token)

    message_history.append({"role": "assistant", "content": msg.content})
    await msg.update()
