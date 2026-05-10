# Referência Completa — Lua + CraftOS + CP437

---

## PALAVRAS-CHAVE RESERVADAS

```
and       — operador lógico E
break     — sai do loop atual
do        — inicia um bloco
else      — alternativa do if
elseif    — alternativa condicional encadeada
end       — fecha um bloco
false     — valor booleano falso
for       — loop com contador ou iterador
function  — declara uma função
goto      — salta para um label
if        — condicional
in        — usado no for genérico
local     — declara variável local
nil       — ausência de valor
not       — operador lógico NÃO
or        — operador lógico OU
repeat    — inicia loop repeat/until
return    — retorna valor de uma função
then      — corpo do if
true      — valor booleano verdadeiro
until     — condição de saída do repeat
while     — loop com condição
```

---

## TIPOS DE DADOS

```
nil       — ausência de valor
boolean   — true ou false
number    — inteiro ou float
string    — texto
table     — array, objeto e dicionário ao mesmo tempo
function  — função
thread    — coroutine
userdata  — dado externo (C)
```

---

## VARIÁVEIS GLOBAIS ESPECIAIS

```
_VERSION  — versão do Lua ex: "Lua 5.4"
_G        — table com todos os globais do programa
_ENV      — ambiente de execução atual
```

---

## METAMETHODS

### Aritméticos
```
__add     — operador +
__sub     — operador -
__mul     — operador *
__div     — operador /
__mod     — operador %
__pow     — operador ^
__unm     — operador - unário
__idiv    — operador // divisão inteira
```

### Bitwise
```
__band    — operador &
__bor     — operador |
__bxor    — operador ~ binário
__bnot    — operador ~ unário
__shl     — operador <<
__shr     — operador >>
```

### Comparação
```
__eq      — operador ==
__lt      — operador <
__le      — operador <=
```

### Comportamento
```
__index     — disparado ao ler chave inexistente
__newindex  — disparado ao escrever chave inexistente
__call      — disparado ao chamar a table como função
__tostring  — disparado ao chamar tostring()
__len       — disparado ao usar o operador #
__concat    — disparado ao usar o operador ..
__gc        — disparado pelo garbage collector
__close     — disparado em to-be-closed variables
__name      — define nome do tipo para debug
__mode      — define weak table: "k", "v" ou "kv"
```

---

## FUNÇÕES GLOBAIS

```
assert(v, msg)          — erro se v for false ou nil
collectgarbage(opt)     — controla o garbage collector
dofile(file)            — executa um ficheiro Lua
error(msg, level)       — lança um erro
getmetatable(t)         — retorna a metatable de t
ipairs(t)               — iterador de arrays (índice, valor)
load(chunk)             — compila string como função
loadfile(file)          — compila ficheiro como função
next(t, key)            — próximo par chave-valor da table
pairs(t)                — iterador de tables (chave, valor)
pcall(fn, ...)          — chama fn de forma protegida
print(...)              — imprime no terminal
rawequal(a, b)          — compara sem __eq
rawget(t, k)            — lê sem __index
rawlen(v)               — tamanho sem __len
rawset(t, k, v)         — escreve sem __newindex
require(name)           — carrega um módulo
select(n, ...)          — retorna do argumento n em diante
setmetatable(t, mt)     — define a metatable de t
tonumber(v, base)       — converte para número
tostring(v)             — converte para string
type(v)                 — retorna o tipo de v como string
unpack(t)               — espalha valores da table (legado)
xpcall(fn, handler, ...) — pcall com handler de erro personalizado
```

---

## BIBLIOTECA `math`

```
math.pi             — constante π (3.14159...)
math.huge           — infinito positivo
math.maxinteger     — maior inteiro possível
math.mininteger     — menor inteiro possível

math.abs(x)         — valor absoluto
math.ceil(x)        — arredonda para cima
math.floor(x)       — arredonda para baixo
math.sqrt(x)        — raiz quadrada
math.max(...)       — maior valor entre os argumentos
math.min(...)       — menor valor entre os argumentos
math.fmod(x, y)     — resto da divisão float
math.modf(x)        — retorna parte inteira e decimal
math.exp(x)         — e elevado a x
math.log(x, b)      — logaritmo de x na base b
math.sin(x)         — seno de x (radianos)
math.cos(x)         — cosseno de x (radianos)
math.tan(x)         — tangente de x (radianos)
math.asin(x)        — arco seno
math.acos(x)        — arco cosseno
math.atan(x, y)     — arco tangente
math.random(m, n)   — número aleatório entre m e n
math.randomseed(x)  — define semente do random
math.tointeger(x)   — converte para inteiro ou nil
math.type(x)        — retorna "integer", "float" ou false
```

---

## BIBLIOTECA `string`

```
string.len(s)            — tamanho da string
string.sub(s, i, j)      — substring do índice i ao j
string.rep(s, n, sep)    — repete s n vezes com separador sep
string.reverse(s)        — inverte a string
string.upper(s)          — converte para maiúsculas
string.lower(s)          — converte para minúsculas
string.byte(s, i)        — código numérico do char na posição i
string.char(n)           — char correspondente ao código n
string.format(fmt, ...)  — formata string (estilo printf)
string.find(s, pat)      — posição do padrão em s
string.match(s, pat)     — captura do padrão em s
string.gmatch(s, pat)    — iterador de todas as capturas do padrão
string.gsub(s, pat, rep) — substitui todas as ocorrências do padrão
string.dump(fn)          — serializa função em bytecode
```

### Especificadores do `string.format`
```
%s        — string
%d        — inteiro
%f        — float
%.2f      — float com 2 casas decimais
%05d      — inteiro com zeros à esquerda (5 dígitos)
%10s      — alinhado à direita (10 chars)
%-10s     — alinhado à esquerda (10 chars)
%x        — hexadecimal minúsculo
%X        — hexadecimal maiúsculo
%q        — string com aspas escaped
%%        — char % literal
```

### Padrões de string (equivalente ao Regex)
```
.         — qualquer char
%a        — letras
%d        — dígitos
%l        — minúsculas
%u        — maiúsculas
%s        — espaços
%p        — pontuação
%w        — letras e dígitos
%c        — chars de controlo
%x        — hexadecimal

*         — 0 ou mais (guloso)
+         — 1 ou mais (guloso)
?         — 0 ou 1
-         — 0 ou mais (não guloso)

()        — captura grupo
[abc]     — um de a, b ou c
[^abc]    — nenhum de a, b ou c
^         — início da string
$         — fim da string
```

---

## BIBLIOTECA `table`

```
table.insert(t, val)        — insere val no fim de t
table.insert(t, pos, val)   — insere val na posição pos
table.remove(t, pos)        — remove e retorna elemento na posição pos
table.concat(t, sep)        — junta todos os elementos em string
table.sort(t, fn)           — ordena t com função comparadora opcional
table.unpack(t, i, j)       — espalha elementos de i até j
table.pack(...)             — empacota argumentos numa table com campo n
table.move(t1, f, e, pos, t2) — move elementos de t1 para t2
```

---

## BIBLIOTECA `coroutine`

```
coroutine.create(fn)      — cria uma coroutine a partir de fn
coroutine.resume(co, ...) — inicia ou continua co passando valores
coroutine.yield(...)      — pausa a coroutine e devolve valores ao resume
coroutine.status(co)      — retorna "running", "suspended", "dead" ou "normal"
coroutine.wrap(fn)        — cria coroutine e retorna função que a resume
coroutine.isyieldable()   — retorna true se pode fazer yield agora
coroutine.running()       — retorna a coroutine atual e se é a principal
```

---

## BIBLIOTECA `os` (Lua padrão + CraftOS)

```
os.time()                 — tempo atual em segundos desde epoch
os.clock()                — tempo de CPU consumido pelo programa
os.date(fmt)              — data e hora formatada
os.exit()                 — termina o programa

— Exclusivos CraftOS —
os.pullEvent(filter)      — aguarda e retorna o próximo evento
os.pullEventRaw(filter)   — igual mas captura o evento "terminate"
os.queueEvent(name, ...)  — adiciona evento personalizado à fila
os.startTimer(t)          — dispara evento "timer" após t segundos
os.cancelTimer(id)        — cancela um timer pelo id
os.sleep(t)               — pausa a execução por t segundos
os.getComputerID()        — retorna o ID numérico do computador
os.getComputerLabel()     — retorna o label do computador
os.setComputerLabel(l)    — define o label do computador
os.reboot()               — reinicia o computador
os.shutdown()             — desliga o computador
os.version()              — retorna a versão do CraftOS
os.loadAPI(path)          — carrega uma API (método legado)
os.unloadAPI(name)        — descarrega uma API (método legado)
```

---

## BIBLIOTECA `fs` (CraftOS)

```
fs.open(path, mode)       — abre ficheiro ("r","w","a","rb","wb")
fs.list(path)             — lista ficheiros e pastas no caminho
fs.exists(path)           — retorna true se o caminho existe
fs.isDir(path)            — retorna true se for uma pasta
fs.makeDir(path)          — cria pasta e subpastas
fs.delete(path)           — apaga ficheiro ou pasta
fs.copy(from, to)         — copia ficheiro ou pasta
fs.move(from, to)         — move ou renomeia ficheiro ou pasta
fs.combine(path, child)   — junta dois caminhos corretamente
fs.getName(path)          — retorna o nome do ficheiro no caminho
fs.getDir(path)           — retorna a pasta pai do caminho
fs.getSize(path)          — retorna o tamanho em bytes
fs.getFreeSpace(path)     — retorna espaço livre em bytes
fs.find(pattern)          — lista ficheiros por padrão com wildcards
fs.isReadOnly(path)       — retorna true se for apenas leitura
fs.getDrive(path)         — retorna o nome do drive ("hdd","rom",etc)
fs.complete(partial, path) — autocompleta nome de ficheiro
```

### Métodos do file handle (retornado por `fs.open`)
```
handle.read()             — lê um char ou byte
handle.readLine()         — lê uma linha
handle.readAll()          — lê o conteúdo inteiro
handle.write(text)        — escreve texto ou byte
handle.writeLine(text)    — escreve texto com newline
handle.flush()            — força escrita do buffer no disco
handle.close()            — fecha o ficheiro
handle.seek(whence, off)  — move o cursor ("set","cur","end")
```

---

## BIBLIOTECA `term` (CraftOS)

```
term.write(text)              — escreve texto na posição atual do cursor
term.clear()                  — limpa o terminal inteiro
term.clearLine()              — limpa a linha atual
term.setCursorPos(x, y)       — move o cursor para x, y
term.getCursorPos()           — retorna x, y do cursor atual
term.getSize()                — retorna largura, altura do terminal
term.setTextColor(color)      — define cor do texto
term.setBackgroundColor(color) — define cor do fundo
term.getTextColor()           — retorna cor do texto atual
term.getBackgroundColor()     — retorna cor do fundo atual
term.isColor()                — retorna true se suporta cores
term.scroll(n)                — faz scroll n linhas para cima
term.setCursorBlink(bool)     — ativa ou desativa piscar do cursor
term.blit(text, fg, bg)       — escreve com cor de texto e fundo por char
term.redirect(target)         — redireciona output para outro terminal
term.restore()                — restaura o terminal original
term.current()                — retorna o terminal atual
term.native()                 — retorna o terminal nativo do computador
```

---

## BIBLIOTECA `peripheral` (CraftOS)

```
peripheral.find(type)         — encontra periférico pelo tipo
peripheral.wrap(side)         — retorna API do periférico no lado
peripheral.getType(side)      — retorna o tipo do periférico no lado
peripheral.isPresent(side)    — retorna true se há periférico no lado
peripheral.getName(p)         — retorna o nome de rede do periférico
peripheral.getNames()         — lista todos os periféricos conectados
peripheral.getMethods(side)   — lista métodos disponíveis do periférico
peripheral.call(side, method) — chama método no periférico do lado
```

### Lados válidos
```
"top"     — cima
"bottom"  — baixo
"front"   — frente
"back"    — trás
"left"    — esquerda
"right"   — direita
```

---

## BIBLIOTECA `colors` (CraftOS)

```
colors.white        — 1
colors.orange       — 2
colors.magenta      — 4
colors.lightBlue    — 8
colors.yellow       — 16
colors.lime         — 32
colors.pink         — 64
colors.gray         — 128
colors.lightGray    — 256
colors.cyan         — 512
colors.purple       — 1024
colors.blue         — 2048
colors.brown        — 4096
colors.green        — 8192
colors.red          — 16384
colors.black        — 32768

colors.combine(...) — junta múltiplas cores num conjunto bitmask
colors.subtract(set, color) — remove uma cor do conjunto
colors.test(set, color)     — retorna true se a cor está no conjunto
colors.toBlit(color)        — converte cor para char do blit
```

### Chars do blit
```
"0" — white       "8" — lightGray
"1" — orange      "9" — cyan
"2" — magenta     "a" — purple
"3" — lightBlue   "b" — blue
"4" — yellow      "c" — brown
"5" — lime        "d" — green
"6" — pink        "e" — red
"7" — gray        "f" — black
```

---

## BIBLIOTECA `textutils` (CraftOS)

```
textutils.serialize(t)          — converte table para string Lua
textutils.unserialize(s)        — converte string Lua para table
textutils.serializeJSON(t)      — converte table para JSON
textutils.unserializeJSON(s)    — converte JSON para table
textutils.formatTime(t, h24)    — formata tempo (true = 24h, false = 12h)
textutils.tabulate(...)         — imprime tabela formatada no terminal
textutils.pagedTabulate(...)    — igual mas com paginação
textutils.slowPrint(s, rate)    — imprime char a char com velocidade rate
textutils.pagedPrint(s)         — imprime com paginação automática
textutils.complete(text, env)   — autocompleta código Lua
```

---

## BIBLIOTECA `redstone` (CraftOS)

```
redstone.getInput(side)              — retorna true se há sinal no lado
redstone.setOutput(side, bool)       — ativa ou desativa sinal no lado
redstone.getOutput(side)             — retorna true se está a emitir sinal
redstone.getAnalogInput(side)        — retorna força do sinal (0-15)
redstone.setAnalogOutput(side, n)    — define força do sinal (0-15)
redstone.getAnalogOutput(side)       — retorna força do sinal emitido
redstone.getBundledInput(side)       — retorna conjunto de cores ativas
redstone.setBundledOutput(side, set) — define conjunto de cores a emitir
redstone.getBundledOutput(side)      — retorna conjunto emitido
```

---

## BIBLIOTECA `turtle` (CraftOS — só em Turtles)

### Movimento
```
turtle.forward()    — move para frente
turtle.back()       — move para trás
turtle.up()         — move para cima
turtle.down()       — move para baixo
turtle.turnLeft()   — roda 90° à esquerda
turtle.turnRight()  — roda 90° à direita
```

### Mineração
```
turtle.dig()        — minera o bloco à frente
turtle.digUp()      — minera o bloco acima
turtle.digDown()    — minera o bloco abaixo
```

### Colocação
```
turtle.place()      — coloca bloco à frente
turtle.placeUp()    — coloca bloco acima
turtle.placeDown()  — coloca bloco abaixo
```

### Inventário
```
turtle.select(slot)         — seleciona slot (1-16)
turtle.getSelectedSlot()    — retorna slot selecionado
turtle.getItemCount(slot)   — quantidade de itens no slot
turtle.getItemSpace(slot)   — espaço disponível no slot
turtle.getItemDetail(slot)  — detalhes do item no slot
turtle.drop(count)          — larga itens à frente
turtle.dropUp(count)        — larga itens acima
turtle.dropDown(count)      — larga itens abaixo
turtle.suck(count)          — pega itens à frente
turtle.suckUp(count)        — pega itens acima
turtle.suckDown(count)      — pega itens abaixo
turtle.transferTo(slot, n)  — transfere itens para outro slot
turtle.compareTo(slot)      — compara slot atual com outro
```

### Inspeção
```
turtle.detect()         — retorna true se há bloco à frente
turtle.detectUp()       — retorna true se há bloco acima
turtle.detectDown()     — retorna true se há bloco abaixo
turtle.inspect()        — retorna dados do bloco à frente
turtle.inspectUp()      — retorna dados do bloco acima
turtle.inspectDown()    — retorna dados do bloco abaixo
turtle.compare()        — compara bloco à frente com slot atual
turtle.compareUp()      — compara bloco acima com slot atual
turtle.compareDown()    — compara bloco abaixo com slot atual
```

### Outros
```
turtle.craft(limit)     — crafta usando o inventário como grid
turtle.refuel(count)    — abastece com combustível do slot atual
turtle.getFuelLevel()   — retorna nível atual de combustível
turtle.getFuelLimit()   — retorna limite máximo de combustível
turtle.equipLeft()      — equipa item da mão esquerda
turtle.equipRight()     — equipa item da mão direita
```

---

## EVENTOS DO CRAFTOS

```
timer              — timer disparado (id)
alarm              — alarme do os.setAlarm (id)
key                — tecla pressionada (keyCode, isHeld)
key_up             — tecla solta (keyCode)
char               — char digitado (char)
mouse_click        — clique do rato (button, x, y)
mouse_up           — botão do rato solto (button, x, y)
mouse_scroll       — scroll do rato (direction, x, y)
mouse_drag         — rato arrastado (button, x, y)
monitor_touch      — toque no monitor (side, x, y)
monitor_resize     — monitor redimensionado (side)
peripheral         — periférico conectado (side)
peripheral_detach  — periférico desconectado (side)
redstone           — sinal de redstone mudou
disk               — disco inserido (side)
disk_eject         — disco removido (side)
http_success       — pedido HTTP bem sucedido (url, handle)
http_failure       — pedido HTTP falhou (url, error)
websocket_success  — websocket conectado (url, handle)
websocket_failure  — websocket falhou (url, error)
websocket_message  — mensagem websocket recebida (url, msg, binary)
websocket_closed   — websocket fechado (url)
modem_message      — mensagem de modem (side, channel, replyChannel, msg, distance)
turtle_inventory   — inventário da turtle mudou
terminate          — Ctrl+T pressionado (só com pullEventRaw)
```

---

## BIBLIOTECA `http` (CraftOS)

```
http.get(url, headers)          — pedido GET síncrono
http.post(url, body, headers)   — pedido POST síncrono
http.request(url, body, headers) — pedido assíncrono (usa eventos)
http.checkURL(url)              — verifica se URL é permitida
http.websocket(url, headers)    — abre conexão websocket
```

---

## BIBLIOTECA `modem` (CraftOS — periférico)

```
modem.open(channel)             — abre canal para receber mensagens
modem.close(channel)            — fecha canal
modem.closeAll()                — fecha todos os canais
modem.isOpen(channel)           — retorna true se canal está aberto
modem.transmit(ch, reply, msg)  — envia mensagem no canal
modem.isWireless()              — retorna true se for wireless
modem.getNameLocal()            — retorna nome local na rede com fio
```

---

## INVENTÁRIO — métodos comuns de baús e periféricos

```
inv.list()                      — lista todos os itens com slot e dados
inv.getItemDetail(slot)         — detalhes completos do item no slot
inv.getItemLimit(slot)          — máximo de itens no slot
inv.size()                      — número total de slots
inv.pushItems(target, slot, count, toSlot) — empurra itens para outro inventário
inv.pullItems(source, slot, count, toSlot) — puxa itens de outro inventário
```

---

## CARACTERES CP437 — Advanced Monitor

> Usa `string.char(N)` para gerar o char pelo código decimal.

### ASCII Imprimível (32–126)
```
 32  (espaço)   33  !    34  "    35  #    36  $    37  %    38  &    39  '
 40  (          41  )    42  *    43  +    44  ,    45  -    46  .    47  /
 48  0          49  1    50  2    51  3    52  4    53  5    54  6    55  7
 56  8          57  9    58  :    59  ;    60  <    61  =    62  >    63  ?
 64  @          65  A    66  B    67  C    68  D    69  E    70  F    71  G
 72  H          73  I    74  J    75  K    76  L    77  M    78  N    79  O
 80  P          81  Q    82  R    83  S    84  T    85  U    86  V    87  W
 88  X          89  Y    90  Z    91  [    92  \    93  ]    94  ^    95  _
 96  `          97  a    98  b    99  c   100  d   101  e   102  f   103  g
104  h         105  i   106  j   107  k   108  l   109  m   110  n   111  o
112  p         113  q   114  r   115  s   116  t   117  u   118  v   119  w
120  x         121  y   122  z   123  {   124  |   125  }   126  ~
```

### Setas e Símbolos (1–31)
```
  1  ☺   2  ☻   3  ♥   4  ♦   5  ♣   6  ♠   7  •   8  ◘
  9  ○  10  ◙  11  ♂  12  ♀  13  ♪  14  ♫  15  ☼  16  ►
 17  ◄  18  ↕  19  ‼  20  ¶  21  §  22  ▬  23  ↨  24  ↑
 25  ↓  26  →  27  ←  28  ∟  29  ↔  30  ▲  31  ▼
```

### Blocos e Preenchimento
```
176  ░   — sombra leve
177  ▒   — sombra média
178  ▓   — sombra escura
219  █   — bloco sólido cheio
220  ▄   — meio bloco inferior
223  ▀   — meio bloco superior
221  ▌   — meio bloco esquerdo
222  ▐   — meio bloco direito
```

### Linhas Simples
```
196  ─   — horizontal
179  │   — vertical
218  ┌   — canto superior esquerdo
191  ┐   — canto superior direito
192  └   — canto inferior esquerdo
217  ┘   — canto inferior direito
195  ├   — T esquerdo
180  ┤   — T direito
194  ┬   — T superior
193  ┴   — T inferior
197  ┼   — cruz
```

### Linhas Duplas
```
205  ═   — horizontal dupla
186  ║   — vertical dupla
201  ╔   — canto duplo superior esquerdo
187  ╗   — canto duplo superior direito
200  ╚   — canto duplo inferior esquerdo
188  ╝   — canto duplo inferior direito
203  ╦   — T duplo superior
202  ╩   — T duplo inferior
204  ╠   — T duplo esquerdo
185  ╣   — T duplo direito
206  ╬   — cruz dupla
```

### Linhas Mistas (simples + dupla)
```
213  ╒   — canto sup. esq. (h duplo, v simples)
214  ╓   — canto sup. esq. (h simples, v duplo)
183  ╖   — canto sup. dir. (h simples, v duplo)
189  ╜   — canto inf. dir. (h simples, v duplo)
190  ╛   — canto inf. dir. (h duplo, v simples)
198  ╞   — T esquerdo (h duplo, v simples)
199  ╟   — T esquerdo (h simples, v duplo)
209  ╤   — T superior (h duplo, v simples)
210  ╥   — T superior (h simples, v duplo)
211  ╘   — canto inf. esq. (h duplo, v simples)
212  ╙   — canto inf. esq. (h simples, v duplo)
215  ╫   — cruz mista vertical
216  ╪   — cruz mista horizontal
```

### Letras Latinas Estendidas (úteis para PT/BR)
```
128  Ç   130  é   131  â   132  ä   133  à   134  å
135  ç   136  ê   137  ë   138  è   139  ï   140  î
141  ì   142  Ä   143  Å   144  É   145  æ   146  Æ
147  ô   148  ö   149  ò   150  û   151  ù   152  ÿ
153  Ö   154  Ü   160  á   161  í   162  ó   163  ú
164  ñ   165  Ñ   166  ª   167  º
```

### Símbolos Especiais
```
127  ⌂   — casa
155  ¢   — cêntimo
156  £   — libra
157  ¥   — yen
168  ¿   — interrogação invertida
169  ⌐   — negação
170  ¬   — not lógico
171  ½   — metade
172  ¼   — um quarto
240  ≡   — idêntico
241  ±   — mais ou menos
242  ≥   — maior ou igual
243  ≤   — menor ou igual
246  ÷   — divisão
248  °   — grau
249  ∙   — ponto médio
250  ·   — ponto centrado
251  √   — raiz quadrada
252  ⁿ   — n superscript
253  ²   — dois superscript
254  ■   — quadrado sólido pequeno
```

---

## NOTAS RÁPIDAS — Monitor

```
string.char(N)    — gera char pelo código decimal
#texto            — largura em células (1 char = 1 célula)
mon.getSize()     — retorna largura, altura disponíveis
mon.setTextScale  — escala do texto (0.5 a 5)
blit por char     — cada char da string fg/bg representa uma célula
```

### Referência de bordas rápida
```
Borda simples   →  ┌─┐  │  └─┘   (218,196,191,179,192,217)
Borda dupla     →  ╔═╗  ║  ╚═╝   (201,205,187,186,200,188)
Barra prog.     →  █░   (219, 176)
Separador       →  ─ ou ═ repetido
Setas de menu   →  ► ◄ ▲ ▼  (16,17,30,31)
```
