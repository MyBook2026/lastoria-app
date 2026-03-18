import Cocoa
import WebKit

func savePath() -> URL {
    let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("LaStoria")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("progressi.json")
}

func loadSaved() -> String {
    guard let d = try? Data(contentsOf: savePath()),
          let s = String(data: d, encoding: .utf8) else { return "null" }
    return s
}

class MsgHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ c: WKUserContentController, didReceive msg: WKScriptMessage) {
        switch msg.name {
        case "saveProgress":
            if let s = msg.body as? String {
                if s == "null" {
                    try? FileManager.default.removeItem(at: savePath())
                } else {
                    try? s.data(using: .utf8)?.write(to: savePath())
                }
            }
        case "openMail":
            if let s = msg.body as? String, let u = URL(string: s) {
                NSWorkspace.shared.open(u)
            }
        default: break
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ n: Notification) {
        buildMenu()
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x:0,y:0,width:1280,height:800)
        let ww = min(CGFloat(1100), screen.width - 40)
        let wh = min(CGFloat(820), screen.height - 40)
        window = NSWindow(
            contentRect: NSRect(
                x: screen.origin.x + (screen.width - ww) / 2,
                y: screen.origin.y + (screen.height - wh) / 2,
                width: ww, height: wh),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "La Tua Storia"
        window.minSize = NSSize(width: 720, height: 560)

        let cfg = WKWebViewConfiguration()
        let uc = WKUserContentController()
        let handler = MsgHandler()
        uc.add(handler, name: "saveProgress")
        uc.add(handler, name: "openMail")
        cfg.userContentController = uc
        webView = WKWebView(frame: .zero, configuration: cfg)
        window.contentView = webView

        let saved = loadSaved()
        let bridge = "<script>window.__NATIVE_MAC__=true;window.__SAVED_DATA__=\(saved);</script>"
        let html = AppHTML.html.replacingOccurrences(of: "<head>", with: "<head>\(bridge)")
        webView.loadHTMLString(html, baseURL: nil)

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { true }

    func buildMenu() {
        let bar = NSMenu()
        let appItem = NSMenuItem(); bar.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Informazioni", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Esci", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); bar.addItem(editItem)
        let editMenu = NSMenu(title: "Modifica"); editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Taglia",  action: #selector(NSText.cut(_:)),       keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copia",   action: #selector(NSText.copy(_:)),      keyEquivalent: "c")
        editMenu.addItem(withTitle: "Incolla", action: #selector(NSText.paste(_:)),     keyEquivalent: "v")
        editMenu.addItem(withTitle: "Seleziona tutto", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        NSApplication.shared.mainMenu = bar
    }
}

enum AppHTML {
    static let html = #"""
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>La Tua Storia</title>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,400&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
<style>
:root{--ink:#1a1714;--ink2:#4a4540;--ink3:#8a837a;--paper:#faf8f4;--paper2:#f2ede4;--paper3:#e8e0d2;--gold:#b8935a;--gold2:#d4aa72;--red:#8b2c2c;--serif:'Cormorant Garamond',Georgia,serif;--sans:'DM Sans',system-ui,sans-serif;--max:780px}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:var(--sans);background:var(--paper);color:var(--ink);min-height:100vh;overflow-x:hidden}
header{text-align:center;padding:56px 24px 40px;border-bottom:1px solid var(--paper3)}
.ornament{font-family:var(--serif);font-size:26px;color:var(--gold);letter-spacing:8px;display:block;margin-bottom:16px;opacity:.7}
h1{font-family:var(--serif);font-size:clamp(32px,5vw,56px);font-weight:300;line-height:1.1;color:var(--ink);margin-bottom:12px}
h1 em{font-style:italic;color:var(--gold)}
.subtitle{font-size:14px;font-weight:300;color:var(--ink3);max-width:460px;margin:0 auto;line-height:1.6}
main{max-width:var(--max);margin:0 auto;padding:0 24px 80px}
.screen{display:none}.screen.active{display:block}
.progress-bar{width:100%;height:2px;background:var(--paper3);margin:36px 0 44px;border-radius:2px;overflow:hidden}
.progress-fill{height:100%;background:linear-gradient(90deg,var(--gold),var(--gold2));border-radius:2px;transition:width .6s cubic-bezier(.4,0,.2,1)}
.progress-label{text-align:center;font-size:11px;color:var(--ink3);letter-spacing:1.5px;text-transform:uppercase;margin-top:-28px;margin-bottom:28px}
.autosave-badge{display:inline-flex;align-items:center;gap:5px;font-size:10px;color:var(--gold);letter-spacing:1px;opacity:0;transition:opacity .3s;margin-left:10px}
.autosave-badge.visible{opacity:1}
.autosave-dot{width:5px;height:5px;border-radius:50%;background:var(--gold)}
.chapter-badge{display:inline-flex;align-items:center;background:var(--paper2);border:1px solid var(--paper3);border-radius:20px;padding:5px 14px;font-size:10px;font-weight:500;color:var(--gold);letter-spacing:2px;text-transform:uppercase;margin-bottom:24px}
.question-card{background:white;border:1px solid var(--paper3);border-radius:16px;padding:36px;box-shadow:0 2px 16px rgba(0,0,0,.04)}
.question-meta{font-size:10px;font-weight:500;color:var(--ink3);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:14px}
.question-text{font-family:var(--serif);font-size:clamp(20px,3vw,28px);font-weight:400;line-height:1.3;color:var(--ink);margin-bottom:10px}
.question-hint{font-size:13px;color:var(--ink3);font-style:italic;margin-bottom:24px;line-height:1.6}
textarea{width:100%;min-height:130px;border:1.5px solid var(--paper3);border-radius:10px;padding:14px 18px;font-family:var(--serif);font-size:17px;line-height:1.7;color:var(--ink);background:var(--paper);resize:vertical;outline:none;transition:border-color .2s,background .2s}
textarea:focus{border-color:var(--gold);background:white}
textarea::placeholder{color:var(--ink3);font-style:italic}
.btn-row{display:flex;justify-content:space-between;align-items:center;margin-top:24px;gap:12px}
.btn{font-family:var(--sans);font-size:14px;font-weight:500;padding:11px 26px;border-radius:8px;cursor:pointer;transition:all .2s;letter-spacing:.3px;border:none}
.btn-primary{background:var(--ink);color:var(--paper)}.btn-primary:hover{background:var(--ink2);transform:translateY(-1px)}
.btn-ghost{background:transparent;color:var(--ink3);border:1px solid var(--paper3)}.btn-ghost:hover{border-color:var(--ink3);color:var(--ink2)}
.btn-gold{background:var(--gold);color:white;padding:13px 32px;font-size:15px}.btn-gold:hover{background:var(--gold2);transform:translateY(-1px)}
.skip-link{font-size:13px;color:var(--ink3);cursor:pointer;text-decoration:underline;text-underline-offset:3px;background:none;border:none;font-family:var(--sans)}
.save-indicator{display:flex;align-items:center;gap:8px;margin-top:16px;padding:10px 16px;background:var(--paper2);border-radius:8px;font-size:12px;color:var(--ink3)}
.save-indicator .dot{width:7px;height:7px;border-radius:50%;background:var(--gold);flex-shrink:0}
.save-indicator strong{color:var(--ink2)}
.cover-content{text-align:center;padding:56px 0 32px}
.cover-content>p{font-family:var(--serif);font-size:18px;font-weight:300;color:var(--ink2);line-height:1.8;max-width:540px;margin:0 auto 36px}
.cover-content>p strong{font-weight:600;color:var(--ink)}
.name-input-wrap{max-width:340px;margin:0 auto 28px}
.name-input-wrap label{display:block;font-size:11px;letter-spacing:1.5px;text-transform:uppercase;color:var(--ink3);margin-bottom:7px;font-weight:500}
.name-input-wrap input{width:100%;border:1.5px solid var(--paper3);border-radius:8px;padding:11px 14px;font-family:var(--serif);font-size:20px;text-align:center;background:white;color:var(--ink);outline:none;transition:border-color .2s}
.name-input-wrap input:focus{border-color:var(--gold)}
.features-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;margin:40px 0}
.feature-card{background:white;border:1px solid var(--paper3);border-radius:12px;padding:20px;text-align:left}
.feature-icon{font-family:var(--serif);font-size:24px;color:var(--gold);margin-bottom:10px;display:block}
.feature-card h3{font-size:13px;font-weight:500;margin-bottom:5px}
.feature-card p{font-size:12px;color:var(--ink3);line-height:1.5;margin:0}
.restore-banner{display:none;background:#fffbf4;border:1px solid var(--gold2);border-radius:12px;padding:20px 24px;margin:28px 0 0;flex-direction:column;gap:14px}
.restore-actions{display:flex;gap:10px;flex-wrap:wrap}
.generating-screen{text-align:center;padding:72px 0}
.spinner{width:56px;height:56px;border:2px solid var(--paper3);border-top-color:var(--gold);border-radius:50%;animation:spin 1.4s linear infinite;margin:0 auto 28px}
@keyframes spin{to{transform:rotate(360deg)}}
.generating-title{font-family:var(--serif);font-size:26px;font-weight:300;color:var(--ink);margin-bottom:10px}
.generating-sub{font-size:13px;color:var(--ink3);line-height:1.6}
.generating-steps{margin:36px auto;max-width:340px;text-align:left}
.gen-step{display:flex;align-items:center;gap:10px;padding:9px 0;font-size:13px;color:var(--ink3);border-bottom:1px solid var(--paper2);transition:color .5s}
.gen-step.done{color:var(--ink2)}.gen-step.active{color:var(--ink)}
.step-dot{width:7px;height:7px;border-radius:50%;background:var(--paper3);flex-shrink:0;transition:background .5s}
.gen-step.done .step-dot{background:var(--gold)}
.gen-step.active .step-dot{background:var(--gold2);animation:pd 1s ease-in-out infinite}
@keyframes pd{0%,100%{opacity:1}50%{opacity:.3}}
.story-nav{position:sticky;top:0;z-index:50;background:rgba(250,248,244,.92);backdrop-filter:blur(8px);border-bottom:1px solid var(--paper3);padding:10px 24px;display:flex;align-items:center;justify-content:space-between;margin:0 -24px;gap:10px}
.story-nav-title{font-family:var(--serif);font-size:15px;font-style:italic;color:var(--ink2);flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.btn-sm{font-family:var(--sans);font-size:11px;font-weight:500;padding:6px 14px;border-radius:6px;cursor:pointer;border:1px solid var(--paper3);background:white;color:var(--ink2);transition:all .2s;white-space:nowrap}
.btn-sm.accent{background:var(--ink);color:white;border-color:var(--ink)}
.story-header{text-align:center;padding:56px 0 44px;border-bottom:1px solid var(--paper3);margin-bottom:52px}
.book-title{font-family:var(--serif);font-size:clamp(28px,5vw,48px);font-weight:300;font-style:italic;color:var(--ink);margin-bottom:10px;line-height:1.15}
.book-author{font-size:12px;font-weight:300;color:var(--ink3);letter-spacing:2px;text-transform:uppercase}
.chapter{margin-bottom:60px}
.chapter-title{font-family:var(--serif);font-size:clamp(22px,4vw,34px);font-weight:300;font-style:italic;color:var(--gold);margin-bottom:7px;line-height:1.2}
.chapter-num{font-size:10px;font-weight:500;letter-spacing:2px;text-transform:uppercase;color:var(--ink3);margin-bottom:20px;display:block}
.chapter-divider{width:56px;height:1px;background:var(--paper3);margin:0 0 28px}
.chapter-text{font-family:var(--serif);font-size:clamp(16px,2.2vw,19px);font-weight:300;line-height:1.85;color:var(--ink)}
.chapter-text p{margin-bottom:1.4em}
.chapter-text p:first-child::first-letter{font-size:3.2em;font-weight:600;float:left;line-height:.8;margin:5px 9px 0 0;color:var(--gold);font-family:var(--serif)}
.story-divider{text-align:center;color:var(--gold);font-family:var(--serif);font-size:22px;letter-spacing:12px;margin:44px 0;opacity:.5}
.error-box{background:#fff5f5;border:1px solid #fecaca;border-radius:8px;padding:12px 16px;color:var(--red);font-size:13px;margin-top:12px;display:none}
footer{text-align:center;padding:28px 24px;border-top:1px solid var(--paper3);font-size:11px;color:var(--ink3);letter-spacing:.5px}
@media print{header,.story-nav,footer,.btn,button{display:none!important}body{background:white}.screen{display:block!important}#screen-cover,#screen-questions,#screen-generating{display:none!important}}
</style>
</head>
<body>
<header>
  <span class="ornament">❧ ✦ ❧</span>
  <h1>La Tua <em>Storia</em></h1>
  <p class="subtitle">Un'autobiografia letteraria, a partire dalle tue parole.</p>
</header>
<main>
  <div id="screen-cover" class="screen active">
    <div class="cover-content">
      <p>Ogni vita è un romanzo in attesa di essere scritto.<br><strong>Rispondi alle domande</strong> con calma — puoi chiudere l'app e riprendere quando vuoi. I tuoi progressi vengono salvati automaticamente.</p>
      <div class="name-input-wrap">
        <label for="user-name">Il tuo nome</label>
        <input type="text" id="user-name" placeholder="Come ti chiami?" autocomplete="given-name">
      </div>
      <div class="features-grid">
        <div class="feature-card"><span class="feature-icon">✦</span><h3>Prosa letteraria</h3><p>Non un elenco. Un racconto vero con voce e stile.</p></div>
        <div class="feature-card"><span class="feature-icon">❧</span><h3>7 capitoli</h3><p>Dall'infanzia al presente, ogni epoca ha il suo respiro.</p></div>
        <div class="feature-card"><span class="feature-icon">◆</span><h3>Salvataggio automatico</h3><p>Chiudi pure quando vuoi. Ritrovi tutto qui.</p></div>
        <div class="feature-card"><span class="feature-icon">⁕</span><h3>Invio diretto</h3><p>A fine questionario apre la tua email già pronta.</p></div>
      </div>
      <button class="btn btn-gold" onclick="startQuestions()">Inizia la tua storia →</button>
      <div id="restore-banner" class="restore-banner">
        <p><strong>Hai una sessione in corso.</strong><br><span id="restore-info"></span></p>
        <div class="restore-actions">
          <button class="btn btn-ghost" style="font-size:13px;padding:8px 14px" onclick="clearAndRestart()">Ricomincia da capo</button>
          <button class="btn btn-primary" style="font-size:13px;padding:8px 14px" onclick="restoreSession()">Riprendi da dove eri →</button>
        </div>
      </div>
    </div>
  </div>
  <div id="screen-questions" class="screen">
    <div class="progress-bar"><div class="progress-fill" id="progress-fill" style="width:0%"></div></div>
    <p class="progress-label" id="progress-label">Domanda 1</p>
    <div id="chapter-badge" class="chapter-badge"><span id="chapter-name">Cap. I</span></div>
    <div class="question-card">
      <p class="question-meta" id="q-meta">Domanda 1</p>
      <p class="question-text" id="q-text"></p>
      <p class="question-hint" id="q-hint"></p>
      <textarea id="q-answer" placeholder="Scrivi qui la tua risposta…" rows="6"></textarea>
      <div class="error-box" id="q-error">Scrivi almeno qualche parola per continuare.</div>
    </div>
    <div class="btn-row">
      <button class="btn btn-ghost" id="btn-prev" onclick="prevQuestion()">← Indietro</button>
      <button class="skip-link" onclick="skipQuestion()">Salta questa domanda</button>
      <button class="btn btn-primary" id="btn-next" onclick="nextQuestion()">Avanti →</button>
    </div>
    <div class="save-indicator">
      <div class="dot"></div>
      <span><strong>Salvataggio automatico attivo.</strong> Chiudi pure l'app — ritrovi tutto qui alla riapertura.</span>
    </div>
    <div id="export-bar" style="display:none;margin-top:28px;background:white;border:1px solid var(--paper3);border-left:3px solid var(--gold);border-radius:10px;padding:20px 24px;">
      <p style="font-family:var(--serif);font-size:17px;color:var(--ink);margin-bottom:6px;">Hai completato il questionario.</p>
      <p style="font-size:13px;color:var(--ink3);line-height:1.6;margin-bottom:16px;">Clicca il pulsante — si apre la tua email già compilata con tutto il necessario.</p>
      <button class="btn btn-gold" onclick="exportAnswers()">✉ Invia le risposte a Lorenzo</button>
    </div>
  </div>
  <div id="screen-story" class="screen">
    <div class="story-nav">
      <span class="story-nav-title" id="story-nav-title">La mia storia</span>
      <div style="display:flex;gap:8px;">
        <button class="btn-sm" onclick="restartApp()">← Ricomincia</button>
        <button class="btn-sm accent" onclick="window.print()">Stampa / PDF</button>
      </div>
    </div>
    <div class="story-header">
      <div class="book-title" id="book-title">La mia storia</div>
      <div class="book-author" id="book-author">Un'autobiografia in sette capitoli</div>
    </div>
    <div id="story-content"></div>
    <div class="story-divider">· · ·</div>
    <p style="text-align:center;font-family:var(--serif);font-size:14px;color:var(--ink3);font-style:italic;margin-bottom:60px;">Fine</p>
  </div>
</main>
<footer>La Tua Storia ✦ · Progressi salvati automaticamente sul tuo Mac</footer>
<script>
const CHAPTERS=[
  {num:"I",name:"Le origini",questions:[
    {q:"Dove e quando sei nato/a?",hint:"Città, regione, anno. Racconta l'atmosfera di quel luogo."},
    {q:"Cosa sai delle tue origini familiari?",hint:"Nonni, bisnonni, origini geografiche o culturali della tua famiglia."},
    {q:"Com'era il luogo in cui sei cresciuto/a?",hint:"Un quartiere, una campagna, una città? Cosa ricordi dell'ambiente fisico?"},
    {q:"Chi erano i tuoi genitori? Come li descriveresti?",hint:"Il loro carattere, il loro lavoro, come ti hanno fatto sentire."},
  ]},
  {num:"II",name:"L'infanzia",questions:[
    {q:"Qual è il tuo primo ricordo?",hint:"Non importa se è piccolo o apparentemente banale. Descrivilo."},
    {q:"Cosa ti piaceva fare da bambino/a?",hint:"Giochi, passatempi, luoghi speciali."},
    {q:"Chi era importante nella tua vita da piccolo/a?",hint:"Un amico, un parente, un vicino di casa, un insegnante."},
    {q:"C'è una canzone o una musica che associi a un momento dell'infanzia?",hint:"Basta che evochi qualcosa: un viaggio, una festa, una voce."},
    {q:"C'è stato un momento difficile durante l'infanzia?",hint:"Non sei obbligato/a a rispondere. Anche solo un accenno va bene."},
  ]},
  {num:"III",name:"La giovinezza",questions:[
    {q:"Com'eri da adolescente?",hint:"Il tuo carattere, come ti vedevi, come ti vedevano gli altri."},
    {q:"Qual è un momento di cui vai fiero/a in quegli anni?",hint:"Un risultato, una scelta, qualcosa che ti ha definito."},
    {q:"C'è stato qualcuno che ha cambiato il corso della tua vita da giovane?",hint:"Un amico, un amore, un insegnante, un libro."},
    {q:"C'è un libro, un film o una storia che ti ha cambiato?",hint:"Cosa ti ha aperto una porta che non sapevi esistesse?"},
    {q:"Cosa sognavi per il tuo futuro a 18 anni?",hint:"Le aspirazioni, i sogni, le paure di allora."},
  ]},
  {num:"IV",name:"Le scelte",questions:[
    {q:"Qual è stata la decisione più difficile che hai mai preso?",hint:"Può essere qualcosa di intimo e personale."},
    {q:"C'è qualcosa che hai abbandonato e di cui ti sei mai pentito/a?",hint:"Un percorso, una relazione, un'occasione."},
    {q:"Hai vissuto all'estero, cambiato città o fatto un grande cambiamento?",hint:"Se sì, cosa ti ha spinto/a e cosa hai trovato."},
    {q:"C'è un luogo dove ti sei sentito/a stranamente a tuo agio?",hint:"Una città, un paesaggio, una casa non tua. Cosa aveva di speciale?"},
    {q:"Come descriveresti il tuo rapporto con il rischio?",hint:"Sei stato/a più prudente o avventuroso/a nella vita?"},
  ]},
  {num:"V",name:"Il lavoro e la vocazione",questions:[
    {q:"Cosa fai, o hai fatto, nella vita lavorativa?",hint:"La professione, il mestiere, come hai trascorso il tuo tempo."},
    {q:"Quando hai capito cosa volevi fare?",hint:"O non lo hai mai capito del tutto — anche questo è una storia."},
    {q:"C'è qualcosa che fai con vera passione, fuori dal lavoro?",hint:"Un'arte, uno sport, un impegno, una cura."},
    {q:"C'è un viaggio che ti ha insegnato qualcosa?",hint:"Non importa se era lontano o vicino. Cosa hai capito che prima non sapevi?"},
    {q:"Qual è la cosa più importante che hai imparato lavorando?",hint:"Una lezione di vita, non solo professionale."},
  ]},
  {num:"VI",name:"Gli affetti",questions:[
    {q:"Chi sono le persone più importanti della tua vita?",hint:"Partner, figli, amici, familiari. Descrivi uno di loro."},
    {q:"Com'è stata la tua storia d'amore più significativa?",hint:"Non c'è bisogno di dettagli intimi — racconta l'essenza."},
    {q:"Hai avuto una perdita che ti ha segnato profondamente?",hint:"Una persona, un luogo, un'epoca. Puoi rispondere brevemente o saltare."},
    {q:"Cosa ti ha insegnato l'amicizia?",hint:"Un amico in particolare, o l'amicizia in generale."},
  ]},
  {num:"VII",name:"Chi sono oggi",questions:[
    {q:"Come ti descriveresti oggi, in tre parole o in una frase?",hint:"Non quello che fai — quello che sei."},
    {q:"Cosa ti ha cambiato di più nella vita?",hint:"Un evento, un incontro, un'idea."},
    {q:"C'è qualcosa che ascolti o leggi oggi che dice qualcosa su chi sei diventato/a?",hint:"Non il migliore in assoluto — quello che senti più tuo ora."},
    {q:"Di cosa vai più fiero/a nella tua vita?",hint:"Non deve essere un successo pubblico. Può essere qualcosa di silenzioso."},
    {q:"C'è qualcosa che vorresti dire alle generazioni future?",hint:"Un consiglio, una verità, un augurio."},
    {q:"Come vorresti essere ricordato/a?",hint:"La tua ultima risposta. Prenditi il tempo che ti serve."},
  ]},
];
const allQ=[];CHAPTERS.forEach(ch=>ch.questions.forEach(q=>allQ.push({...q,chapter:ch})));
let curQ=0,answers=new Array(allQ.length).fill(''),userName='';
function saveProgress(){
  answers[curQ]=document.getElementById('q-answer').value.trim();
  const d=JSON.stringify({q:curQ,n:userName,a:answers.slice()});
  if(window.__NATIVE_MAC__)window.webkit.messageHandlers.saveProgress.postMessage(d);
  else try{localStorage.setItem('lastoria_v2',d)}catch(e){}
  showBadge();
}
function loadSaved(){
  if(window.__NATIVE_MAC__&&window.__SAVED_DATA__)return window.__SAVED_DATA__;
  try{const r=localStorage.getItem('lastoria_v2');return r?JSON.parse(r):null}catch(e){return null}
}
function showBadge(){
  const b=document.getElementById('autosave-badge');if(!b)return;
  b.classList.add('visible');clearTimeout(b._t);b._t=setTimeout(()=>b.classList.remove('visible'),2400);
}
window.addEventListener('DOMContentLoaded',()=>{
  const s=loadSaved();
  if(s&&(s.q>0||(s.a&&s.a.some(a=>a)))){
    document.getElementById('restore-banner').style.display='flex';
    const r=(s.a||[]).filter(a=>a&&a.length>0).length;
    document.getElementById('restore-info').textContent=`${s.n?s.n+' — ':''}Domanda ${(s.q||0)+1} di ${allQ.length} · ${r} risposte già salvate`;
    if(s.n)document.getElementById('user-name').value=s.n;
  }
});
function restoreSession(){
  const s=loadSaved();if(!s)return;
  curQ=s.q||0;(s.a||[]).forEach((a,i)=>{if(i<answers.length)answers[i]=a;});
  userName=s.n||'Autore';showScreen('screen-questions');renderQ();
}
function clearAndRestart(){
  if(window.__NATIVE_MAC__)window.webkit.messageHandlers.saveProgress.postMessage('null');
  else try{localStorage.removeItem('lastoria_v2')}catch(e){}
  document.getElementById('restore-banner').style.display='none';
}
function showScreen(id){document.querySelectorAll('.screen').forEach(s=>s.classList.remove('active'));document.getElementById(id).classList.add('active');window.scrollTo(0,0);}
function startQuestions(){userName=document.getElementById('user-name').value.trim()||'Autore';clearAndRestart();showScreen('screen-questions');renderQ();}
function renderQ(){
  const q=allQ[curQ],tot=allQ.length;
  document.getElementById('progress-fill').style.width=(curQ/tot*100)+'%';
  document.getElementById('progress-label').innerHTML=`Domanda ${curQ+1} di ${tot} <span class="autosave-badge" id="autosave-badge"><span class="autosave-dot"></span> Salvato</span>`;
  document.getElementById('chapter-name').textContent=`Cap. ${q.chapter.num} · ${q.chapter.name}`;
  document.getElementById('q-meta').textContent=`Domanda ${curQ+1}`;
  document.getElementById('q-text').textContent=q.q;
  document.getElementById('q-hint').textContent=q.hint;
  document.getElementById('q-answer').value=answers[curQ]||'';
  document.getElementById('q-error').style.display='none';
  document.getElementById('btn-prev').style.visibility=curQ===0?'hidden':'visible';
  document.getElementById('btn-next').textContent=curQ===tot-1?'Concludi ✦':'Avanti →';
  document.getElementById('q-answer').focus();
  const ta=document.getElementById('q-answer');clearTimeout(ta._t);
  ta.oninput=()=>{clearTimeout(ta._t);ta._t=setTimeout(()=>{answers[curQ]=ta.value.trim();saveProgress();},800);};
}
function saveAns(){answers[curQ]=document.getElementById('q-answer').value.trim();}
function nextQuestion(){
  saveAns();
  if(!answers[curQ]||answers[curQ].length<2){document.getElementById('q-error').style.display='block';return;}
  document.getElementById('q-error').style.display='none';saveProgress();
  if(curQ<allQ.length-1){curQ++;renderQ();}else showExportBanner();
}
function prevQuestion(){saveAns();saveProgress();if(curQ>0){curQ--;renderQ();}}
function skipQuestion(){answers[curQ]='';saveProgress();if(curQ<allQ.length-1){curQ++;renderQ();}else showExportBanner();}
function showExportBanner(){
  document.getElementById('progress-fill').style.width='100%';
  document.getElementById('progress-label').textContent='Questionario completato ✦';
  document.querySelector('.question-card').style.display='none';
  document.querySelector('.btn-row').style.display='none';
  document.getElementById('chapter-badge').style.display='none';
  document.getElementById('export-bar').style.display='block';
  window.scrollTo(0,0);
}
function exportAnswers(){
  let r='';
  CHAPTERS.forEach(ch=>{
    r+=`\n=== CAPITOLO ${ch.num}: ${ch.name.toUpperCase()} ===\n`;
    ch.questions.forEach(q=>{
      const i=allQ.findIndex(aq=>aq.q===q.q&&aq.chapter.num===ch.num);
      r+=`D: ${q.q}\nR: ${answers[i]||'[nessuna risposta]'}\n\n`;
    });
  });
  const o=encodeURIComponent(`${userName} — La mia Storia`);
  const b=encodeURIComponent(`Ciao Lorenzo,\n\nho completato il questionario. Trovi tutte le mie risposte qui sotto.\n\n${userName}\n\n════════════════════════════════════════\nLE MIE RISPOSTE\n════════════════════════════════════════\n${r}\n════════════════════════════════════════\nLA MIA SCELTA (cancella le altre due)\n════════════════════════════════════════\n\n  ► MANOSCRITTO DIGITALE — € 197\n    PDF impaginato con copertina personalizzata.\n    Consegna via email entro 7 giorni.\n\n  ► LIBRO CARTACEO — € 397\n    Stampa professionale 17×24 cm, spedita a casa.\n\n  ► LIBRO + 5 COPIE — € 597\n    5 copie rilegate, spedizione inclusa.\n\n════════════════════════════════════════\nPAGAMENTO (cancella quello che non usi)\n════════════════════════════════════════\n\n  PayPal:   @LorenzoPatti472\n  Bonifico: IBAN IT75 P084 4001 6010 0000 0200 011\n            Intestato a: Lorenzo Patti\n            Causale: "${userName} — La mia Storia"\n\nGrazie.\n${userName}`);
  const url=`mailto:pattilorenzo@ymail.com?subject=${o}&body=${b}`;
  if(window.__NATIVE_MAC__)window.webkit.messageHandlers.openMail.postMessage(url);
  else window.location.href=url;
}
function restartApp(){
  if(!confirm('Vuoi ricominciare? Le risposte andranno perse.'))return;
  curQ=0;answers.fill('');userName='';clearAndRestart();
  document.getElementById('user-name').value='';showScreen('screen-cover');
}
</script>
</body>
</html>
"""#
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
