CC      ?= clang
CFLAGS  := -shared -fPIC -O2
LDFLAGS := -ldl
TARGET  := kvm_reg_fix4.so
SRC     := kvm_reg_fix4.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGET)

.PHONY: all clean
