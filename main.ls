const DEBUGGING = no
const MOE-ID = 18979
isCordova = location.href is /^file:...android_asset/
isDeviceReady = not isCordova
document.addEventListener \deviceready (->
  try navigator.splashscreen.hide!
  isDeviceReady := yes
  window.do-load!
), false

window.show-info = ->
  ref = window.open \Android.html \_blank \location=no
  on-stop = ({url}) -> ref.close! if url is /quit\.html/
  on-exit = ->
    ref.removeEventListener \loadstop on-stop
    ref.removeEventListener \exit     on-exit
  ref.addEventListener \loadstop on-stop
  ref.addEventListener \exit     on-exit

window.do-load = ->
  return unless isDeviceReady
  $(window).on \hashchange -> grok-hash!
  $('body').addClass \cordova if isCordova

  init = ->
    fetch MOE-ID unless grok-hash!
    $ \#query .keyup lookup .change lookup .keypress lookup .keydown lookup .on \input lookup
    $ \#query .on \focus -> @select!
    $ \#query .show!.focus!
    $ \a .on \click ->
      fill-query $(@).text!
      return false

  grok-hash = ->
    return false unless location.hash is /^#./
    try
      val = decodeURIComponent location.hash.substr 1
      return true if val is prevVal
      $ \#query .show!.focus!
      fill-query val
      return true if val is prevVal
    return false

  fill-query = ->
    try
      $ \#query .val it
      unless navigator.userAgent is /Android|iPhone|iPad|Mobile/
        $ \#query .focus!
        $ \#query .get 0 .select!
      lookup!
      return true
    return false

  prevId = prevVal = titleToId = titleRegex = charRegex = null

  lookup = -> do-lookup $(\#query).val!

  do-lookup = (val) ->
    return true if prevVal is val
    id = titleToId[val]
    return true if prevId is id or not id
    prevId := id
    prevVal := val
    try history.pushState null, null, "##val" unless "#{location.hash}" is "##val"
    fetch id
    return true

  fetch = ->
    return fill-html MOE if it is MOE-ID
    $.get "data/#{ it % 100 }/#it.html" fill-html

  fill-html = (html) ->
    $ \#result .html ((for chunk in html.replace(/(.)\u20DE/g, "<span class='part-of-speech'>$1</span>").split(//(</?div>)//)
      chunk.replace do
        if chunk is /<h1/ then charRegex else titleRegex
        -> """<a href="##it">#it</a>"""
    ) * "")
    window.scroll-to 0 0

  if isCordova => fetch = (id) ->
    return fill-html MOE if id is MOE-ID
    txt <- $.get "pack/#{ id % 1000 }.txt"
    const keyStr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
    bz2 = new Uint8Array(new ArrayBuffer Math.ceil(txt.length * 0.75))
    i = j = 0
    while i < txt.length
      enc1 = keyStr.indexOf txt.charAt i++
      enc2 = keyStr.indexOf txt.charAt i++
      enc3 = keyStr.indexOf txt.charAt i++
      enc4 = keyStr.indexOf txt.charAt i++
      chr1 = enc1 .<<. 2 .|. enc2 .>>. 4
      chr2 = (enc2 .&. 15) .<<. 4 .|. enc3 .>>. 2
      chr3 = (enc3 .&. 3) .<<. 6 .|. enc4
      bz2[j++] = chr1
      bz2[j++] = chr2 unless enc3 is 64
      bz2[j++] = chr3 unless enc4 is 64
      chr1 = chr2 = chr3 = enc1 = enc2 = enc3 = enc4 = ''
    json = bzip2.simple bzip2.array bz2
    if json.match(//"#id":("[^"]+")//)
      fill-html JSON.parse(RegExp.$1)

  <- $.ajax { type: \GET, url: \trie.js, dataType: \script, +cache } .then

  titleToId := {}
  walk = (prefix, obj) ->
    for k, v of obj
      if k is \$
        titleToId[prefix] = v
      else if v instanceof Object
        walk prefix + k, v
      else
        titleToId[prefix + k] = v

  chars = ''
  for k, v of window.trie
    chars += "|#k"
    walk k, v

  titles = [k.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&") for k of titleToId]
  titles.sort (a, b) -> b.length - a.length
  titleRegex := new RegExp((titles * \|), \g)
  charRegex := new RegExp(chars.substring(1), \g)

  check = (prefix, obj, entries) ->
    for k, v of obj
      if k is \$
        entries.push prefix
      else if v instanceof Object
        check prefix + k, v, entries
      else
        entries.push(prefix + k)

  prefixEntries = {}

  $(\#query).autocomplete do
    position:
      my: "left bottom"
      at: "left top"
    select: (e, {item: {value}}) ->
      fill-query value
      return true
    change: (e, {item}) ->
      fill-query value
      return true
    source: ({term}, cb) ->
      # first, find the minimal suffix
      return cb [] unless term.length
      first = term.slice(0, 1)
      titles = trie[first]
      return cb [] unless titles
      entries = prefixEntries[first]
      unless entries
        entries = []
        check first, titles, entries
        prefixEntries[first] = entries
      while term.length
        results = [ e for e in entries | e.index-of(term) is 0 ]
        if results.length is 1
          do-lookup results.0
          return cb []
        return cb results if results.length
        term = term.slice(0, term.length-1)
      cb []

  init!

const MOE = """
  <h1 class='title'>萌</h1><span class='bopomofo'>ㄇㄥˊ</span><div>
      <div><span class='part-of-speech'>名</span>
          <ol><li>
                <p class='definition'>草木初生的芽。說文解字：「萌，艸芽也。」唐．韓愈､劉師服､侯喜､軒轅彌明．石鼎聯句：「秋瓜未落蒂，凍芋強抽萌。」</p>
                 
              </li><li>
                <p class='definition'>事物發生的開端或徵兆。韓非子．說林上：「聖人見微以知萌，見端以知末。」漢．蔡邕．對詔問灾異八事：「以杜漸防萌，則其救也。」</p>
                 
              </li><li>
                <p class='definition'>人民。通「氓」。如：「萌黎」､「萌隸」。</p>
                 
              </li><li>
                <p class='definition'>姓。如五代時蜀有萌慮。</p>
                 
              </li></ol>
          </div><div><span class='part-of-speech'>動</span>
          <ol><li>
                <p class='definition'>發芽。如：「萌芽」。楚辭．王逸．九思．傷時：「明風習習兮龢暖，百草萌兮華榮。」</p>
                 
              </li><li>
                <p class='definition'>發生。如：「故態復萌」。管子．牧民：「惟有道者，能備患於未形也，故禍不萌。」三國演義．第一回：「若萌異心，必獲惡報。」</p>
                 
              </li></ol>
          </div>
"""
