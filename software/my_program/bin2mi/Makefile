all:
	gcc bin2coe.c -o bin2coe -std=c99 -Wall -Wextra
	./bin2coe
	gcc coe2newcoe.c -o coe2newcoe -std=c99 -Wall -Wextra
	./coe2newcoe
	gcc coe2mi.c -o coe2mi -std=c99 -Wall -Wextra
	./coe2mi
	rm start_mid.coe
	rm start.coe
	rm bin2coe
	rm coe2newcoe
	rm coe2mi
clean:
	rm start.mi
	


