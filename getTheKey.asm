INCLUDE Irvine32.inc

.data
Xmargin BYTE ? ; Margem da lateral esquerda usada para centralizar o ambiente do jogo
CurrentLine BYTE 0 ; Auxilia na contagem de linhas ao desenhar o cenario

minMap WORD ? ; Limite minimo do espaco onde o jogador pode se locomover
			  ; Formato (Limite X | Limite Y)
maxMap WORD ? ; Limite maximo do espaco onde o jogador pode se locomover
			  ; Formato (Limite X | Limite Y)

logo1 byte ' ______     ______     ______      ______   __  __     ______        __  __     ______     __  __ ',0dh,0ah,0
logo2 byte '/\  ___\   /\  ___\   /\__  _\    /\__  _\ /\ \_\ \   /\  ___\      /\ \/ /    /\  ___\   /\ \_\ \ ',0dh,0ah,0
logo3 byte '\ \ \__ \  \ \  __\   \/_/\ \/    \/_/\ \/ \ \  __ \  \ \  __\      \ \  _"-.  \ \  __\   \ \____ \',0dh,0ah,0
logo4 byte ' \ \_____\  \ \_____\    \ \_\       \ \_\  \ \_\ \_\  \ \_____\     \ \_\ \_\  \ \_____\  \/\_____\ ',0dh,0ah,0
logo5 byte '  \/_____/   \/_____/     \/_/        \/_/   \/_/\/_/   \/_____/      \/_/\/_/   \/_____/   \/_____/ ',0dh,0ah,0

mapHeight = 35
mapWidth = 98 ; LENGHTOF logo1 = 98

BUFSIZE = mapHeight*mapWidth
mapMatrix BYTE BUFSIZE DUP (?)
mapaFileName BYTE 'nivel1.mapa',0

;Estrutura Player
playerSymbol BYTE 0FEh ; Armazena o caracter que representa o jogador
playerX BYTE ? ; Posicao X do jogador na tela
playerY BYTE ? ; Posicao Y do jogador na tela

.code

main PROC
INICIALIZADOR: ; Configuracoes iniciais
	call LoadMapa
	call ReadChar ; Espera para ajustar a tela, será substituido por outro funçao
	call GetMaxXY ; Pega o tamanho do terminal atual para configurar as posicoes na tela
	sub dl, LENGTHOF logo1 
	shr dl,1
	mov Xmargin,dl ; Calcula a magem esquerda em funcao do tamanho da tela e do logo, dessa forma o jogo sempre estará centralizado

	call DrawLogo ; Desenha o logo do jogo 
	call DrawEnigma ; Desenha o local onde ficara o enigma e o proprio enigma (temos que resolver isso)
	call DrawMapa ; Desenha o mapa do labirinto
	mov al, BYTE PTR minMap ; Coloca o jogador em uma posicao predefinida no inicio (mudar essa parte em funcao do mapa)
	inc al
	mov playerX, al
	mov al, BYTE PTR minMap+1
	inc al
	mov playerY, al
	call DrawPlayer ; Desenha o jogador na tela na posicao configurada
MAINLOOP:
	call ReadKey ; Le do teclado alguma tecla
	jz FIM ; Se nao fou apertada nenhuma tecla, pula para o fim da iteracao atual
	call HandleControl ; Caso contrario e realizada uma acao em funcao da tecla apertada
FIM:
	mov eax, 50 ; Configura um delay de 50 milisegundos, isso garante que o jogo nao exija muita da cpu de forma desnecessaria e
				; cause bugs na leitura das teclas
	call delay
	jmp MAINLOOP ; Executa o loop principal do jogo
exit
main ENDP

;---------------------------------------------------
HandleControl PROC
;
; Gerencia o controle do jogo executando a operacao correta em funcao da tecla apertada
; Recebe: eax = tecla que foi acionada
; Retorna: 
;---------------------------------------------------

	cmp ah, 48h ; Verifica se foi a tecla de seta pra cima
	je UP
	cmp ah, 50h ; Seta para baixo
	je Down
	cmp ah, 4dh ; Seta para a direita
	je Right
	cmp ah, 4bh ; Seta para a esquerda
	je Left
	jmp fim ; Se nao foi nenhuma das alternativas, o processo e encerrado
UP:
	mov bl, BYTE PTR minMap+1 ; Recupera o valor do limite do mapa
	inc bl
	cmp playerY, bl ; Se o movimento fizer com que o jogador ultrapasse o limite do mapa, esse movimento nao e realizado
	je fim
	call ClearPlayer ; Limpa o antigo local do jogador
	dec playerY ; Move o jogador para cima
	jmp fim
DOWN:
	mov bl, BYTE PTR maxMap+1
	dec bl
	cmp playerY, bl
	je fim
	call ClearPlayer ; Limpa o antigo local do jogador
	inc playerY
	jmp fim
Left:
	mov bl, BYTE PTR minMap
	inc bl
	cmp playerX, bl
	je fim
	call ClearPlayer ; Limpa o antigo local do jogador
	dec playerX
	jmp fim
Right:
	mov bl, BYTE PTR maxMap
	dec bl
	cmp playerX, bl
	je fim
	call ClearPlayer ; Limpa o antigo local do jogador
	inc playerX
	jmp fim
Fim:
	call DrawPlayer ; Desenha o jogador na nova posicao
	ret
HandleControl ENDP

;---------------------------------------------------	
DrawPlayer PROC
;
; Desenha na tela o jogador em sua posicao atual
; Recebe: Nada
; Retorna: Nada
;---------------------------------------------------	
	call GetTextColor
    push eax

	mov dl, playerX
	mov dh, playerY
	call GoToxy

	mov eax,lightcyan
	call settextcolor
	mov al, playerSymbol
	call WriteChar

	pop eax
	call settextcolor

	ret
DrawPlayer ENDP

;---------------------------------------------------	
ClearPlayer PROC
;
; Limpa a posicao antiga do jogador, evita que forme um rastro na tela devido ao movimento do jogador
; Recebe: Nada
; Retorna: Nada
;---------------------------------------------------
	call GetTextColor
    push eax

	mov dl, playerX
	mov dh, playerY
	call GoToxy

	mov eax,black
	call settextcolor
	mov al, playerSymbol
	call WriteChar

	pop eax
	call settextcolor
	ret
ClearPlayer ENDP

;---------------------------------------------------
LoadMapa PROC
;
; Carrega na memoria um mapa
; Recebe: ? 
; Retorna: ?
;---------------------------------------------------
	mov edx, OFFSET mapaFileName
	call OpenInputFile

	;mov  eax,fileHandle
    mov  edx,OFFSET mapMatrix
    mov  ecx,BUFSIZE
    call ReadFromFile
    ;jc   show_error_message
    ;mov  bytesRead,eax

	mov edx, OFFSET mapMatrix
	call WriteString
	ret
LoadMapa ENDP

;---------------------------------------------------
DrawLogo PROC
;
; Desenha na tela o logo do jogo
; Recebe: ? 
; Retorna: ?
;---------------------------------------------------
	call GetTextColor
    push eax
	
	mov eax,0
	mov eax,lightblue
	call settextcolor

	mov dl, Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy
	mov edx, offset logo1
	call writestring

	mov eax,lightblue
	call settextcolor

	mov dl, Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy
	mov edx, offset logo2
	call writestring

	mov eax,lightcyan
	call settextcolor

	mov dl, Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy
	mov edx, offset logo3
	call writestring

	mov eax,lightgreen
	call settextcolor

	mov dl, Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy
	mov edx, offset logo4
	call writestring

	mov eax,cyan
	call settextcolor

	mov dl, Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy
	mov edx, offset logo5
	call writestring

	pop eax
	call settextcolor

	ret
DrawLogo ENDP

;---------------------------------------------------
DrawEnigma PROC
;
; Desenha na tela o local enigma e o enigma propriamente dito
; Recebe: ? 
; Retorna: ?
;---------------------------------------------------
	mov al, '+'
	mov ecx, LENGTHOF logo1
	inc CurrentLine
	mov dl,Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy 
L1:
	call WriteChar
	loop L1

	mov dl,Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy
	mov ecx, LENGTHOF logo1 - 2
	call WriteChar
	mov al, ' '
L2:
	call WriteChar
	loop L2

	mov al, '+'
	call WriteChar

	mov ecx, LENGTHOF logo1
	mov dl,Xmargin
	mov dh,CurrentLine
	inc CurrentLine
	call GoToxy 
L3:
	call WriteChar
	loop L3
	ret
DrawEnigma ENDP

;---------------------------------------------------
DrawMapa PROC
;
; Desenha na tela o mapa do labirinto
; Recebe: ? 
; Retorna: ?
;---------------------------------------------------
	mov al, 0feh
	mov ecx, mapWidth + 2
	inc CurrentLine
	mov dl,Xmargin
	mov dh,CurrentLine
	mov minMap,dx
	inc CurrentLine
	call GoToxy
L1:
	call WriteChar
	loop L1

	mov al, 0dbh
	mov ecx, mapHeight
L2:
	mov dl, BYTE PTR minMap
	mov dh, CurrentLine
	call GoToxy
	call WriteChar
	add dl, mapWidth + 1
	call GoToxy
	call WriteChar
	inc CurrentLine
	loop L2

	mov al, 0feh
	mov ecx, mapWidth + 2
	mov dl,Xmargin
	mov dh,CurrentLine
	call GoToxy
L3:
	call WriteChar
	loop L3

	mov dl, Xmargin
	add dl, mapWidth + 1
	mov maxMap,dx
	ret
DrawMapa ENDP

END main