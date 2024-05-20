#set text(
  font: "New Computer Modern",
  size: 12pt
)
#set page(paper: "a4", margin: (x: 1cm, y: 1cm), numbering: "1")
#set heading(numbering: "1.")


#align(center)[
  #stack(
    v(12pt),
    text(size: 22pt, weight: "bold")[Wprowadzanie do Cyberbezpieczeństwa],
    v(12pt),
    text(size: 15pt, weight: "semibold")[Instalacja i aktualizacja certyfikatu Let’s Encrypt dla serwera WWW],
    v(12pt),
    text(size: 11pt)[Stanisław Nieradko 193044, Filip Dawidowski 193433, Bartłomiej Krawisz 193319, Krzysztof Nasuta 193328]
  )
]


#outline(title: "Spis treści", target: heading.where(depth: 1))


= Wstęp


Sprawozdanie z projektu dotyczącego instalacji i aktualizacji certyfikatu Let's Encrypt dla serwera WWW wykonanego w ramach przedmiotu Wprowadzenie do Cyberbezpieczeństwa. Przedstawione zostaną w nim kroki niezbędne do zainstalowania certyfikatu Let's Encrypt z użyciem różnych metod weryfikacji właściciela domeny. Zaprezentowany zostanie proces instalacji certyfikatu dla serwera `nginx` oraz `Caddy` w systemie operacyjnym `Ubuntu 22.04`. Wszystkie operacje zostały przeprowadzone na maszynie wirtualnej w chmurze Oracle Cloud Infrastructure (OCI).


= Certyfikaty Let's Encrypt
Let's Encrypt to bezpłatny, automatyczny i wolny urząd certyfikacji (CA) działający dla pożytku publicznego. Jest to usługa dostarczana przez Internet Security Research Group (ISRG).


Zasady funkcjonowania fundacji Let's Encrypt:


- Bezpłatnie: Każdy właściciel domeny może użyć Let's Encrypt do uzyskania zaufanego certyfikatu bez żadnych opłat.
- Automatycznie: Oprogramowanie działające na serwerze może bezproblemowo wchodzić w interakcję z Let's Encrypt, aby uzyskać certyfikat, bezpiecznie skonfigurować go do użytku oraz automatycznie zająć się odnowieniem.
- Bezpiecznie: Let's Encrypt spełnia funkcję platformy do doskonalenia najlepszych praktyk zabezpieczeń TLS, zarówno po stronie CA, jak i pomagając operatorom witryn poprawnie zabezpieczyć swoje serwery.
- Otwarcie: Wszystkie wydane lub cofnięte certyfikaty będą publicznie rejestrowane i dostępne dla każdego do wglądu.
- Wolnie: Protokół automatycznego wydawania oraz odnawiania jest opublikowany jako wolny standard, który każdy może zastosować.
- Wspólnie: Tak jak podstawowe protokoły internetowe, Let's Encrypt to wspólny wysiłek na rzecz społeczności pozostający poza kontrolą jakiejkolwiek organizacji.


= Porównanie dostępnych dostawców certyfikatów


== Let's Encrypt


- Darmowe certyfikaty (90 dni)
- Automatyczne odnawianie (certbot, caddy i inne narzędzia)
- Wsparcie dla wildcardów (tylko DNS-01)
- Duża społeczność i wsparcie


== Płatne certyfikaty


- Dłuższy termin ważności (do 2 lat, chociaż niektóre przeglądarki ograniczają do 1 roku)
- Możliwość wykupienia certyfikatów Organizational Validation (OV) i Extended Validation (EV)
- Wsparcie techniczne


== ZeroSSL


- Zarówno darmowe, jak i płatne certyfikaty
- Pełna konsola oraz REST API do zarządzania certyfikatami
- Monitorowanie certyfikatów SSL


== Cloudflare


- Zarówno darmowe, jak i płatne certyfikaty (większe możliwości konfiguracji szyfrowania oraz wielopoziomowe domeny)
- Zintegrowane z usługami Cloudflare (popularny CDN, firewall i inne usługi)
- Łatwa i natychmiastowa konfiguracja dla użytkowników Cloudflare'a


= Metody autoryzacji domeny


Przy generowaniu certyfikatu Let's Encrypt wymagane jest potwierdzenie, że domena, dla której certyfikat chcemy wygenerować, należy do nas. Możliwe jest to poprzez spełnienie jednego z warunków opisanych w standardzie ACME (Automated Certificate Management Environment). Obecnie wspierane są trzy metody autoryzacji:
- `http-01`
- `dns-01`
- `tls-alpn-01`


#align(center)[
  #table(
    align: center,
    columns: 4,
    [Metoda], [Adres IP], [Nazwa hosta], [Obsługa wildcardów],
    [`http-01`], sym.checkmark, sym.checkmark, sym.times.big,
    [`dns-01`], sym.times.big, sym.checkmark, sym.checkmark,
    [`tls-alpn-01`], sym.checkmark, sym.checkmark, sym.times.big
  )
]


W przeszłości istniała również metoda `tls-sni-01`, która została wycofana z użycia w 2019 roku.


== `HTTP-01`
- Metoda ta jest obecnie najczęściej stosowaną metodą autoryzacji. Polega na umieszczeniu pliku z wygenerowanym przez Let's Encrypt kodem w odpowiednim katalogu na serwerze, który jest dostępny z zewnątrz.
- Let's Encrypt sprawdza, czy plik jest dostępny pod adresem `http://<TWOJA_DOMENA>/.well-known/acme-challenge/<TOKEN>`. Jeśli serwer WWW zwróci odpowiedni kod, jest to potwierdzenie, że domena należy do osoby, która chce wygenerować certyfikat.
- Metoda `HTTP-01` wymaga użycia portu 80 na serwerze, na którym chcemy wygenerować certyfikat.
- Metoda ta jest prosta w implementacji oraz szybka, gdyż nie wymaga żadnych dodatkowych konfiguracji DNS. Potrzebujemy jednak dostępu do serwera HTTP obsługującego naszą domenę.
- Metody tej nie można użyć, aby wygenerować certyfikat wildcard. W przypadku kilku serwerów, każdy z nich musi zwracać ten sam kod.


== `DNS-01`
- Metoda ta polega na dodaniu rekordu TXT do DNS domeny, dla której chcemy wygenerować certyfikat. Rekord ten zawiera, podobnie jak w przypadku `HTTP-01`, wygenerowany przez Let's Encrypt kod.
- Let's Encrypt sprawdza, czy rekord TXT `_acme-challenge.<TWOJA_DOMENA>` zawiera odpowiedni kod. Jeśli tak jest, mamy potwierdzenie, że domena należy do osoby, która chce wygenerować certyfikat.
- Metoda `DNS-01` wymaga dostępu do konfiguracji DNS domeny, dla której chcemy wygenerować certyfikat. Utrudnia to automatyzację procesu generowania certyfikatów. Dostawca DNS musi udostępniać odpowiednie API. Zalecane jest używanie uwierzytelniania API o ograniczonych uprawnieniach bądź walidacja DNS z osobnego serwera, a następnie skopiowanie certyfikatu na serwer.
- Metoda ta jest wolniejsza od `HTTP-01`, gdyż wymaga czasu propagacji rekordów DNS. Jest to jednak jedyna metoda, która pozwala na generowanie certyfikatów wildcard. W przypadku kilku serwerów, wystarczy jedna konfiguracja DNS.


== `TLS-SNI-01`
- Metoda przestarzała
- Do 2019 roku jedną z metod autoryzacji był `TLS-SNI-01`. Polegała ona na przekazaniu przez Let's Encrypt serwerowi specjalnego zapytania TLS, które zawierało wygenerowany przez Let's Encrypt kod. Serwer musiał zwrócić ten sam kod, aby potwierdzić, że domena należy do osoby, która chce wygenerować certyfikat.
- Metoda została wycofana z użycia w 2019 roku i zastąpiona przez `TLS-ALPN-01` z powodu niewystarczającego poziomu bezpieczeństwa.


== `TLS-ALPN-01`
- Polega na przekazaniu przez Let's Encrypt serwerowi specjalnego zapytania TLS, które zawiera wygenerowany przez Let's Encrypt kod. Serwer musi zwrócić ten sam kod, aby potwierdzić, że domena należy do osoby, która chce wygenerować certyfikat.
- Metoda ta jest rzadko stosowana. Nie jest obsługiwana przez Apache, Nginx ani Certbot. Jednym z nielicznych narzędzi, które wspierają tę metodę, jest Caddy.
- Zaletą tej metody jest brak konieczności dostępu do portu 80. Cały proces odbywa się na warstwie TLS.
- Metoda ta, podobnie jak `HTTP-01`, nie pozwala na generowanie certyfikatów wildcard. W przypadku kilku serwerów, każdy z nich musi zwracać ten sam kod.


= Metody instalacji certyfikatu


== Manualna
- Manualna instalacja certyfikatu polega na ręcznym wygenerowaniu certyfikatu Let's Encrypt, a następnie skonfigurowaniu serwera WWW, aby używał tego certyfikatu.
- Do generowania certyfikatów można użyć narzędzi takich jak Certbot lub ZeroSSL. Następnie należy skonfigurować serwer WWW, aby używał wygenerowanego certyfikatu oraz pamiętać o regularnym odnawianiu certyfikatów.
- Metoda ta jest niewygodna i czasochłonna, dlatego zaleca się automatyzację procesu generowania certyfikatów (ACME) ale ma swoje zastosowanie w przypadku systemów, które nie są obsługiwane przez narzędzia automatyzujące.


== Certbot
- Certbot to prosty w użyciu program, który automatyzuje proces uzyskiwania certyfikatów Let's Encrypt. Automatycznie konfiguruje serwer WWW (np. apache, nginx), aby używał nowego certyfikatu, a także automatycznie odnawia certyfikaty, gdy zbliżają się do wygaśnięcia. Certbot wspiera autoryzację `http-01` oraz `dns-01`.
- Certbot jest dostępny na większość popularnych systemów operacyjnych, takich jak Linux, Windows oraz macOS. Dostępne są również wtyczki do popularnych serwerów WWW, takich jak Apache i Nginx, umożliwiające automatyczne przystosowanie konfiguracji używanego serwera WWW.


== Caddy
- Caddy to serwer WWW, który automatycznie obsługuje certyfikaty Let's Encrypt. Wystarczy dodać konfigurację serwera WWW do pliku Caddyfile, a Caddy automatycznie wygeneruje certyfikat Let's Encrypt i skonfiguruje serwer WWW, aby używał tego certyfikatu.
- Caddy obsługuje autoryzację `http-01` oraz `tls-alpn-01`. W przypadku autoryzacji `http-01`, Caddy automatycznie dodaje odpowiednią konfigurację do pliku Caddyfile, aby umożliwić Let's Encrypt weryfikację domeny.
- Caddy jest dostępny na systemy operacyjne Linux, Windows oraz macOS. Oprócz obsługi certyfikatów Let's Encrypt, Caddy oferuje wiele innych funkcji, takich jak load balancing, obsługa protokołu HTTP/2, eksperymentalna obsługa protokołu QUIC czy możliwość konfiguracji poprzez API, dzięki czemu jest to ciekawa alternatywa dla bardziej popularnych serwerów WWW, takich jak Apache czy Nginx.


== Cert-Manager
- cert-manager to narzędzie do zarządzania certyfikatami w środowiskach opartych na Kubernetes. Automatycznie generuje certyfikaty Let's Encrypt dla aplikacji działających w klastrze Kubernetes, a także automatycznie odnawia certyfikaty, gdy zbliżają się do wygaśnięcia.
- cert-manager obsługuje autoryzację `http-01` oraz `dns-01`. W przypadku obu metod, cert-manager automatycznie dodaje odpowiednie zasoby do klastra Kubernetes, aby umożliwić Let's Encrypt weryfikację domeny.


== Dostawcy hostingu
- Wiele firm hostingowych oferuje integrację z Let's Encrypt. W takim przypadku proces generowania certyfikatu jest zautomatyzowany, a użytkownik nie musi się martwić o konfigurację serwera WWW. Jedną z wad takiego rozwiązania jest ograniczona kontrola nad konfiguracją oraz limit na ilość certyfikatów, które można wygenerować.




= Środowiska
Z uwagi na ograniczenia nałożone przez organizację Let's Encrypt, zaleca się używanie certyfikatów wystawionych w środowisku testowym do testowania automatyzacji procesu generowania certyfikatów.


== Staging
- Certyfikaty wystawione w środowisku testowym są podpisane przez inny certyfikat root, co sprawia, że nie są one uznawane przez przeglądarki internetowe.
- Wystawianie certyfikatów w tym środowisku podlega niższym limitom, co pozwala na testowanie automatyzacji procesu wystawiania certyfikatów, bez dużego ryzyka zablokowania dostępu do usługi Let's Encrypt z powodu przekroczenia ograniczeń.
- W przypadku użycia certbot, aby wygenerować certyfikat staging wystarczy dodać flagę `--staging`.


== Production
- Środowisko produkcyjne to środowisko aplikacji dla użytkowników końcowych. Certyfikaty wystawione w tym środowisku są uznawane przez przeglądarki internetowe.
- Wystawianie certyfikatów w środowisku produkcyjnym podlega limitom nałożonym przez organizację Let's Encrypt takimi jak ilość certyfikatów na zarejestrowaną domenę lub ilość zamówień certyfikatów na godzinę. W przypadku przekroczenia limitów, dostęp do usługi może zostać zablokowany na określony czas.
- Certbot domyślnie generuje certyfikaty w środowisku produkcyjnym.


= Prezentacja praktyczna


== nginx
Przykładowa instalacja certyfikatu Let's Encrypt dla serwera WWW `nginx` w systemie operacyjnym `Ubuntu 22.04` z użyciem autoryzacji `http-01`. Komendy należy wykonać jako użytkownik z uprawnieniami administratora. W przypadku użycia innej dystrybucji systemu Linux niż Ubuntu, należy dostosować komendy do używanej dystrybucji.


- Instalacja `nginx` z repozytorium Ubuntu


```bash
apt-get -y update
apt-get install -y nginx
```


#image("./img/update-install-nginx.png")


- Włączenie serwera `nginx`


```bash
systemctl enable nginx
systemctl start nginx
```


- Sprawdzenie statusu serwera `nginx`


```bash
systemctl status nginx
```


#image("./img/status-nginx.png")


- Instalacja `certbot` z repozytorium Ubuntu


Dodatkowo instalujemy pakiet `python3-certbot-nginx`, który pozwoli na automatyczną konfigurację serwera `nginx` do użycia certyfikatu Let's Encrypt.


```bash
apt-get install -y certbot python3-certbot-nginx
```


- Generowanie certyfikatu Let's Encrypt


```bash
certbot --nginx
```


Aby wygenerować certyfikat Let's Encrypt, należy podać adres e-mail, zaakceptować regulamin oraz zdecydować, czy chcemy otrzymywać informacje o nowościach. Następnie należy wybrać domenę, dla której chcemy wygenerować certyfikat. Po zakończeniu procesu, certyfikat zostanie zainstalowany na serwerze `nginx`.


Jeśli chcemy zainstalować certyfikat w środowisku testowym, należy dodać flagę `--staging` do komendy `certbot --nginx`. Aby utworzyć certyfikat bez podawania adresu e-mail, należy dodać flagę `--register-unsafely-without-email`.


#image("./img/certbot.png")




== Caddy


Przykładowa konfiguracja serwera WWW `Caddy` z automatycznym generowaniem certyfikatu Let's Encrypt.


- Instalacja `Caddy` z oficjalnej strony


Pobieranie pliku binarnego `caddy` oraz nadanie uprawnień do wykonywania. Inne metody instalacji dostępne są na stronie #link("https://caddyserver.com/docs/install")[Caddy].


```bash
wget "https://caddyserver.com/api/download?os=linux&arch=amd64" -O caddy
chmod +x caddy
```


- Tworzenie pliku konfiguracyjnego `Caddyfile`


```
# Caddyfile
example.com {
    root * /var/www/html
    file_server
    tls demo@example.com {
        #ca https://acme-staging-v02.api.letsencrypt.org/directory # staging
        ca https://acme-v02.api.letsencrypt.org/directory # production
    }
}
```


- Uruchomienie serwera `Caddy`


Plik `Caddyfile` należy umieścić w katalogu, w którym znajduje się plik binarny `caddy`.


```bash
./caddy run
```


Po uruchomieniu serwera `Caddy`, certyfikat Let's Encrypt zostanie automatycznie wygenerowany i zainstalowany na serwerze.


#image("./img/caddy.png")

