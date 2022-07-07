output = ""
while True:
    f = float(input())
    t = int(input())
    h = format(round(1/f * 10 ** 6 / 2), "#06x")
    high = h[2:4]
    low = h[4:]
    t = str(hex(t))[2::]
    output += f"${high},${low},${t},"
    print(output)
