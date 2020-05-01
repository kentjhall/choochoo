CC      = gcc
CFLAGS  = -g -Wall
LDFLAGS = -g

traind:

.PHONY: coupled
coupled: traind
	cp -f traind /sbin/init
	sed -i "s/ systemd/#systemd/g" /etc/nsswitch.conf
	rm -f /sbin/poweroff /sbin/reboot
	cp -f poweroff /sbin/poweroff
	cp -f reboot /sbin/reboot
	rm -rf /etc/traind
	mkdir /etc/traind
	@touch _dummy.sh
	cp *.sh /etc/traind
	@rm _dummy.sh /etc/traind/_dummy.sh

.PHONY: uncoupled
uncoupled:
	ln -sf /lib/systemd/systemd /sbin/init
	sed -i "s/#systemd/ systemd/g" /etc/nsswitch.conf
	ln -sf /bin/systemctl /sbin/poweroff
	ln -sf /bin/systemctl /sbin/reboot
	rm -rf /etc/traind

.PHONY: decoupled
decoupled: uncoupled
	./poweroff

.PHONY: clean
clean:
	rm -f *.o traind
