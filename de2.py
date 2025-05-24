import serial
import time
import sys

if len(sys.argv) != 4:
    print(f"Uso: {sys.argv[0]} <porta> <baud> <await>")
    exit()

lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam posuere eros in metus molestie venenatis. Aliquam commodo augue a facilisis posuere. Suspendisse vitae ipsum sollicitudin, ornare arcu vel, viverra magna. Fusce eu justo lectus. Proin volutpat."

baudrate = int(sys.argv[2])
wait = int(sys.argv[3])
placa = serial.Serial(sys.argv[1], baudrate)

start = time.time()
#for caractere in lorem:
#    placa.write(caractere.encode())
#    time.sleep(wait/(baudrate))
placa.write(lorem.encode())
#time.sleep(wait/(baudrate))
placa.write(b'\x00')

enviostamp = time.time()
envio = enviostamp - start

#while placa.in_waiting < 256:
#    time.sleep(wait/(200000*baudrate))

#rec = placa.read_all()
rec = placa.read(256)
recebimento = time.time() - enviostamp
print(rec)
print(rec == lorem.encode())
print("tempo total: ", time.time() - start)
print("tempo envio: ", envio)
print("tempo receb: ", recebimento)
