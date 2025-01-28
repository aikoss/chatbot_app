import streamlit as st
from transformers import AutoModelForCausalLM, AutoTokenizer

# Carica il modello GPT-J da Hugging Face
@st.cache(allow_output_mutation=True)
def load_model():
    tokenizer = AutoTokenizer.from_pretrained("EleutherAI/gpt-j-6B")
    model = AutoModelForCausalLM.from_pretrained("EleutherAI/gpt-j-6B")
    tokenizer.pad_token = tokenizer.eos_token
    return tokenizer, model

tokenizer, model = load_model()

# Funzione per generare risposte
def generate_response(prompt):
    inputs = tokenizer(prompt, return_tensors="pt", padding=True, truncation=True)
    response_ids = model.generate(
        inputs["input_ids"],
        attention_mask=inputs["attention_mask"],
        max_length=150,
        do_sample=True,
        temperature=0.7,
        top_p=0.9,
        pad_token_id=tokenizer.eos_token_id
    )
    response = tokenizer.decode(response_ids[0], skip_special_tokens=True)
    return response

# Interfaccia Streamlit
st.title("Chatbot basato su GPT-J")
st.write("Questo chatbot utilizza il modello GPT-J per generare risposte complesse e intelligenti.")

# Input dell'utente
user_input = st.text_input("Scrivi qualcosa per iniziare la conversazione:", "")

if st.button("Invia"):
    if user_input.strip():
        with st.spinner("Sto pensando..."):
            response = generate_response(user_input)
        st.write(f"**Chatbot:** {response}")
    else:
        st.warning("Per favore, inserisci un messaggio!")

st.markdown("---")
st.caption("Creato con ❤️ usando Streamlit e GPT-J")
