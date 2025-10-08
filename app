
import streamlit as st
import re
from math import isclose

st.set_page_config(page_title="Trợ lý Toán 10A1", layout="centered")

st.title("Trợ lý Toán 10A1")
st.subheader("Lớp: 10A1  — Chat & Giải hệ phương trình 2 ẩn")

if "chat_history" not in st.session_state:
    st.session_state.chat_history = []

def parse_linear_equation(eq_text):
    """
    Parse a single linear equation in x and y into coefficients (a, b, c) for ax + by = c.
    Supports forms like: 2x + 3y = 5  or -x + 4*y = 3  or 3 = 2x - y
    Returns (a, b, c) floats or raises ValueError.
    """
    text = eq_text.replace(" ", "").lower()
    # ensure '=' present
    if "=" not in text:
        raise ValueError("Phương trình cần dấu '='")
    left, right = text.split("=", 1)
    def eval_side(side):
        # Replace unary +/− at start with explicit 0+ or 0- to simplify finding terms
        side = re.sub(r'(^|(?<=\()|(?<=[=]))([-+])', r'\1\2', side)
        # find terms like +/-?number?*?x or y or constants
        # match terms containing x or y, and pure numbers
        tokens = re.findall(r'([+-]?[^+-]+)', side)
        a = b = c = 0.0
        for t in tokens:
            # variable x
            if "x" in t:
                coeff = t.replace("*", "").replace("x","")
                if coeff in ("", "+"): coeff = "1"
                if coeff == "-": coeff = "-1"
                a += float(coeff)
            elif "y" in t:
                coeff = t.replace("*", "").replace("y","")
                if coeff in ("", "+"): coeff = "1"
                if coeff == "-": coeff = "-1"
                b += float(coeff)
            else:
                # constant term
                c += float(t)
        return a, b, c
    a1, b1, c1 = eval_side(left)
    a2, b2, c2 = eval_side(right)
    # move all to left: (left - right) = 0 => (a1-a2)x + (b1-b2)y + (c1-c2) = 0
    A = a1 - a2
    B = b1 - b2
    C = c1 - c2
    # we want form A x + B y = -C  (so RHS positive constant)
    return A, B, -C

def solve_2x2(eq1, eq2):
    try:
        a1,b1,c1 = parse_linear_equation(eq1)
        a2,b2,c2 = parse_linear_equation(eq2)
    except Exception as e:
        return {"error": f"Lỗi khi phân tích phương trình: {e}"}
    det = a1*b2 - a2*b1
    if isclose(det, 0.0, abs_tol=1e-9):
        # check for infinite solutions or none
        # If ratios consistent, infinite; else no solution
        # Compare rank via checking proportionality
        if isclose(a1*b2, a2*b1) and isclose(a1*c2, a2*c1) and isclose(b1*c2, b2*c1):
            return {"status":"inf", "message":"Hệ có vô số nghiệm (vô định)."}
        else:
            return {"status":"none", "message":"Hệ vô nghiệm."}
    x = (c1*b2 - c2*b1) / det
    y = (a1*c2 - a2*c1) / det
    return {"status":"one", "x": x, "y": y, "coeffs": (a1,b1,c1,a2,b2,c2)}

st.markdown("---")
st.markdown("### Chat (gõ câu hỏi tiếng Việt)")
user_input = st.text_input("Bạn:", key="user_input")

def bot_reply(text):
    text_lower = text.strip().lower()
    # If text contains '=' or 'x' or 'y' or 'giải', try to extract equations
    if "=" in text_lower or ("x" in text_lower and "y" in text_lower) or "giải" in text_lower:
        # try to split into two equations by newline or ';' or '&&' or 'and'
        parts = re.split(r'[;\n\|]+', text)
        # if only one part, try to split by 'và' or 'and' or ','
        if len(parts) == 1:
            # try splitting around ' và '
            if " và " in text_lower:
                parts = re.split(r' và | and ', text, maxsplit=1)
        if len(parts) >= 2:
            eq1 = parts[0].strip()
            eq2 = parts[1].strip()
            sol = solve_2x2(eq1, eq2)
            if "error" in sol:
                return sol["error"]
            if sol["status"] == "one":
                return f"Nghiệm: x = {sol['x']:.6g}, y = {sol['y']:.6g}"
            else:
                return sol.get("message", "Không thể giải hệ.")
        else:
            return "Vui lòng nhập hai phương trình (mỗi phương trình trên một dòng hoặc ngăn cách bằng ';').\nVí dụ: `2x+3y=5; x-2y=1`"
    # Small conversational replies
    if any(word in text_lower for word in ["xin chào", "hello", "chào"]):
        return "Chào bạn! Mình là Trợ lý Toán 10A1. Gửi 2 phương trình để mình giải hoặc hỏi về toán nhé."
    if "cảm ơn" in text_lower or "thanks" in text_lower:
        return "Không có gì! Nếu cần tiếp, gửi phương trình hoặc câu hỏi nhé."
    if "giúp" in text_lower or "hướng dẫn" in text_lower:
        return "Mình có thể giải hệ 2 ẩn. Nhập hai phương trình (ví dụ `2x+3y=5` và `x-2y=1`) hoặc hỏi chuyện chung."
    # default small talk
    return "Mình chưa hiểu rõ — bạn có thể nhập hai phương trình để giải hoặc hỏi 'giải hệ: 2x+3y=5; x-2y=1'."

if user_input:
    reply = bot_reply(user_input)
    st.session_state.chat_history.append(("Bạn", user_input))
    st.session_state.chat_history.append(("Trợ lý Toán 10A1", reply))
    st.experimental_rerun()

for speaker, text in st.session_state.chat_history[::-1]:
    if speaker == "Bạn":
        st.markdown(f"**Bạn:** {text}")
    else:
        st.markdown(f"**{speaker}:** {text}")

st.markdown("---")
st.markdown("### Giao diện giải nhanh (nhập hai phương trình)")
eq1 = st.text_input("Phương trình 1", key="eq1_input", value="2x+3y=5")
eq2 = st.text_input("Phương trình 2", key="eq2_input", value="x-2y=1")

if st.button("Giải hệ"):
    sol = solve_2x2(eq1, eq2)
    if "error" in sol:
        st.error(sol["error"])
    else:
        if sol["status"] == "one":
            st.success(f"Nghiệm: x = {sol['x']:.6g}, y = {sol['y']:.6g}")
            st.write("Chi tiết hệ số:", sol.get("coeffs"))
        else:
            st.info(sol.get("message", "Không thể giải hệ."))

st.markdown("---")
st.caption("Ứng dụng được viết bởi Trợ lý Toán 10A1 — lớp 10A1. Bạn có thể deploy file này lên Streamlit Cloud hoặc Streamlit Sharing.")
