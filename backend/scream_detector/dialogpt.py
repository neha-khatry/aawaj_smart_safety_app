from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

MODEL_NAME = "microsoft/DialoGPT-medium"

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

# 🔑 IMPORTANT FIX: set pad token explicitly
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(MODEL_NAME)

def generate_reply(prompt):
    inputs = tokenizer(
        prompt + tokenizer.eos_token,
        return_tensors="pt",
        padding=True,
        truncation=True,
        max_length=256
    )

    input_ids = inputs["input_ids"]
    attention_mask = inputs["attention_mask"]

    output_ids = model.generate(
        input_ids=input_ids,
        attention_mask=attention_mask,
        max_length=200,
        do_sample=True,
        temperature=0.7,
        top_p=0.9,
        pad_token_id=tokenizer.eos_token_id,
        repetition_penalty=1.2,
        no_repeat_ngram_size=3
    )

    reply = tokenizer.decode(
        output_ids[0][input_ids.shape[-1]:],
        skip_special_tokens=True
    )

    return reply
