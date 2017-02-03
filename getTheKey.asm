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

mapHeight = 36
mapWidth = 98 ; LENGHTOF logo1 = 98

BUFSIZE = mapHeight*mapWidth + 200 ; tamanho do mapa mais o tamanho do enigma+resposta
BUFFERMAPA BYTE BUFSIZE DUP (?)
mapMatrix BYTE BUFSIZE-200 DUP (?) ; retira 200 referente a parte do enigma
mapaFileName BYTE 'nivel1.mapa',0

;Estrutura Player
playerSymbol BYTE 0FEh ; Armazena o caracter que representa o jogador
playerX BYTE ? ; Posicao X do jogador na tela
playerXAux BYTE ?
playerY BYTE ? ; Posicao Y do jogador na tela
playerYAux BYTE ?
dispositivos BYTE 4 DUP (?) ; Como fazer para checar se esta num dispositivo (uma solucao e armazenar o offset na matriz)

; Estrutura Enigma
enigma BYTE 150 DUP (?)
respostaOriginal BYTE 4 DUP(?)
respostaJogador BYTE 4 DUP(?)

.code
main PROC

INICIALIZADOR: ; Configuracoes iniciais
	call LoadMapaFile
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
GetElementoMatriz PROC
;
; Gerencia o controle do jogo executando a operacao correta em funcao da tecla apertada
; Recebe: nada
; Retorna: al com o elemento encontrado
;---------------------------------------------------
	push ebp
	mov ebp,esp

	mov eax, 0

	mov ax, [ebp + 10] ; Y
	mov bx, [ebp + 8] ; X

	sub al, BYTE PTR minMap+1
	dec al

	sub bl, BYTE PTR minMap
	dec bl

	mov cl, 98
	mul cl ; AX = Y * 98

	movzx cx, bl
	add ax, cx


	mov esi, OFFSET mapMatrix
	add esi, eax
	mov al, [esi]

	pop ebp
	ret 4
GetElementoMatriz ENDP

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

	mov cl, playerX
	mov playerXAux, cl

	mov cl, playerY
	dec cl
	mov playerYAux, cl

	jmp VerificaColisaoLabirinto
DOWN:
	mov bl, BYTE PTR maxMap+1
	dec bl
	cmp playerY, bl
	je fim

	mov cl, playerX
	mov playerXAux, cl

	mov cl, playerY
	inc cl
	mov playerYAux, cl

	jmp VerificaColisaoLabirinto
Left:
	mov bl, BYTE PTR minMap
	inc bl
	cmp playerX, bl
	je fim

	mov cl, playerX
	dec cl
	mov playerXAux, cl

	mov cl, playerY
	mov playerYAux, cl

	jmp VerificaColisaoLabirinto
Right:
	mov bl, BYTE PTR maxMap
	dec bl
	cmp playerX, bl
	je fim

	mov cl, playerX
	inc cl
	mov playerXAux, cl

	mov cl, playerY
	mov playerYAux, cl

	jmp VerificaColisaoLabirinto

VerificaColisaoLabirinto:
	; Verifica se há colisão com os elementos da matriz
	movzx cx, playerYAux
	;dec cx
	push cx
	movzx cx, playerXAux
	push cx
	call GetElementoMatriz

	.IF al == 0dbh
	jmp fim
	.Else
	call ClearPlayer
	mov cl, playerXAux
	mov playerX, cl
	mov cl, playerYAux
	mov playerY, cl
	.ENDIF

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
LoadMapaFile PROC
;
; Carrega na memoria um mapa
; Recebe: ? 
; Retorna: ?
;---------------------------------------------------
; Abertura do arquivo	
	mov edx, OFFSET mapaFileName 
	call OpenInputFile

    mov  edx,OFFSET BUFFERMAPA
    mov  ecx,BUFSIZE
    call ReadFromFile
    ;jc   show_error_message
    ;mov  bytesRead,eax

; Recupera as informacoes sobre a pergunta e o enigma 
	mov edx,OFFSET BUFFERMAPA
	mov eax, OFFSET enigma
; Identifica a pergunta
PerguntaInicio:
	mov cl, [edx]
	cmp cl,'#'
	je PerguntaFim
	mov [eax], cl
	inc eax
	inc edx
	jmp PerguntaInicio
PerguntaFim:
	
	inc edx
	mov eax, OFFSET respostaOriginal
; Identifica a resposta
RespostaInicio:
	mov cl, [edx]
	cmp cl,'#'
	je RespostaFim
	mov [eax], cl
	inc eax
	inc edx
	jmp RespostaInicio
RespostaFim:

	add edx,3
	mov eax, OFFSET mapMatrix
	mov ebx, mapHeight*mapWidth

; Inicializa a matriz do mapa
MapaInicio:
	mov cl, [edx]
	
	cmp cl, 0dh
	jne ColocaNaMatriz

	;Teste
	;push eax
	;mov al, 0dh
	;call WriteChar
	;mov al, 0ah
	;call WriteChar
	;pop eax
	;Teste

	add edx, 2
	jmp MapaInicio

ColocaNaMatriz:
	.IF cl == 'x'
	mov cl, 0dbh
	.ELSEIF cl == 'p'
	mov cl, 0bah
	.ELSEIF cl == 'c'
	mov cl, 0feh
	.ENDIF
	
	;Teste
	;push eax
	;mov al, cl
	;call WriteChar
	;pop eax
	;Teste

	mov [eax], cl
	inc eax
	inc edx
	dec ebx
	jz MapaFim
	jmp MapaInicio

MapaFim:
	ret
LoadMapaFile ENDP

;---------------------------------------------------
DrawLogo PROC
;
; Desenha na tela o logo do jogo
; Recebe: ?
; Retorna: ?
;---------------------------------------------------
	call GetTextColor
    push eax
	
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
	mov ecx, LENGTHOF logo1 - 1
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
	call GoToxy
	call WriteChar
	mov ecx, 5 ;Espacamento esquerdo para comecar a escrever a pergunta
	mov al, ' '
L2:
	call WriteChar
	loop L2

	mov edx, OFFSET enigma
	call WriteString

	mov dl,Xmargin
	mov dh,CurrentLine
	add dl, 99 ; Aponta para o final da linha do meio da caixa do enigma
	call GoToxy
	mov al, '+'
	call WriteChar

	inc CurrentLine
	mov ecx, LENGTHOF logo1 - 1
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
	call GetTextColor
	push eax
	mov eax,white
	call settextcolor

	mov al, 0dbh
	mov ecx, mapWidth + 2
	inc CurrentLine
	mov dl,Xmargin
	mov dh,CurrentLine
	mov minMap,dx
	inc CurrentLine
	call GoToxy
ParedeDeCima:
	call WriteChar
	loop ParedeDeCima

	mov ebx, OFFSET mapMatrix

	mov al, 0dbh
	mov ecx, mapHeight
Labirinto:
	mov dl, BYTE PTR minMap
	mov dh, CurrentLine
	call GoToxy
	call WriteChar; Inicio parede externa esquerda

	push ecx
	mov ecx, mapWidth
	call GetTextColor
	push eax
	mov eax,gray
	call settextcolor
	LabirintoInterno:
		mov al, [ebx]
		.IF al == 0bah
			call GetTextColor
			push eax
			mov eax,lightRed
			call settextcolor
			mov al, 0bah
			call WriteChar
			pop eax
			call settextcolor
		.ELSEIF al == 0feh
			call GetTextColor
			push eax
			mov eax,lightgreen
			call settextcolor
			mov al, 0feh
			call WriteChar
			pop eax
			call settextcolor
		.ELSE
			call WriteChar
		.ENDIF
		
		inc ebx
		loop LabirintoInterno
	pop eax
	call settextcolor
	pop ecx

	mov al, 0dbh
	call WriteChar; Inicio parede externa esquerda
	inc CurrentLine
	dec cx
	jnz Labirinto

	mov al, 0dbh
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

	pop eax

	ret
DrawMapa ENDP

END main