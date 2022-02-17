// Input 0
function makeNoteDom(a,b,c){var d=document.createElement("div");a=document.createTextNode(a);d.appendChild(a);a=document.createElement("div");b=document.createTextNode(b);a.appendChild(b);b=document.createElement("div");b.appendChild(d);b.appendChild(a);c.appendChild(b)}function makeNotes(a,b){for(var c=0;c<a.length;c++)makeNoteDom(a[c].title,a[c].content,b)}
function main(){var a=document.getElementById("notes");makeNotes([{title:"Note 1",content:"Content of Note 1"},{title:"Note 2",content:"Content of Note 2"}],a)}main();
// Input 1
function extend$$module$Input_0(a){for(var b=1;b<arguments.length;b++){var c=arguments[b],d;for(d in c)c.hasOwnProperty(d)&&(a[d]=c[d])}return a}function repeat$$module$Input_0(a,b){return Array(b+1).join(a)}function trimLeadingNewlines$$module$Input_0(a){return a.replace(/^\n*/,"")}function trimTrailingNewlines$$module$Input_0(a){for(var b=a.length;0<b&&"\n"===a[b-1];)b--;return a.substring(0,b)}var blockElements$$module$Input_0="ADDRESS ARTICLE ASIDE AUDIO BLOCKQUOTE BODY CANVAS CENTER DD DIR DIV DL DT FIELDSET FIGCAPTION FIGURE FOOTER FORM FRAMESET H1 H2 H3 H4 H5 H6 HEADER HGROUP HR HTML ISINDEX LI MAIN MENU NAV NOFRAMES NOSCRIPT OL OUTPUT P PRE SECTION TABLE TBODY TD TFOOT TH THEAD TR UL".split(" ");
function isBlock$$module$Input_0(a){return is$$module$Input_0(a,blockElements$$module$Input_0)}var voidElements$$module$Input_0="AREA BASE BR COL COMMAND EMBED HR IMG INPUT KEYGEN LINK META PARAM SOURCE TRACK WBR".split(" ");function isVoid$$module$Input_0(a){return is$$module$Input_0(a,voidElements$$module$Input_0)}function hasVoid$$module$Input_0(a){return has$$module$Input_0(a,voidElements$$module$Input_0)}var meaningfulWhenBlankElements$$module$Input_0="A TABLE THEAD TBODY TFOOT TH TD IFRAME SCRIPT AUDIO VIDEO".split(" ");
function isMeaningfulWhenBlank$$module$Input_0(a){return is$$module$Input_0(a,meaningfulWhenBlankElements$$module$Input_0)}function hasMeaningfulWhenBlank$$module$Input_0(a){return has$$module$Input_0(a,meaningfulWhenBlankElements$$module$Input_0)}function is$$module$Input_0(a,b){return 0<=b.indexOf(a.nodeName)}function has$$module$Input_0(a,b){return a.getElementsByTagName&&b.some(function(c){return a.getElementsByTagName(c).length})}var module$Input_0={};module$Input_0.blockElements=blockElements$$module$Input_0;
module$Input_0.extend=extend$$module$Input_0;module$Input_0.hasMeaningfulWhenBlank=hasMeaningfulWhenBlank$$module$Input_0;module$Input_0.hasVoid=hasVoid$$module$Input_0;module$Input_0.isBlock=isBlock$$module$Input_0;module$Input_0.isMeaningfulWhenBlank=isMeaningfulWhenBlank$$module$Input_0;module$Input_0.isVoid=isVoid$$module$Input_0;module$Input_0.repeat=repeat$$module$Input_0;module$Input_0.trimLeadingNewlines=trimLeadingNewlines$$module$Input_0;module$Input_0.trimTrailingNewlines=trimTrailingNewlines$$module$Input_0;
module$Input_0.voidElements=voidElements$$module$Input_0;





/*
export function extend (destination) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i]
    for (var key in source) {
      if (source.hasOwnProperty(key)) destination[key] = source[key]
    }
  }
  return destination
}

export function repeat (character, count) {
  return Array(count + 1).join(character)
}

export function trimLeadingNewlines (string) {
  return string.replace(/^\n*/                       /*                , '')
}

export function trimTrailingNewlines (string) {
  // avoid match-at-end regexp bottleneck, see #370
  var indexEnd = string.length
  while (indexEnd > 0 && string[indexEnd - 1] === '\n') indexEnd--
  return string.substring(0, indexEnd)
}
/*
export var blockElements = [
  'ADDRESS', 'ARTICLE', 'ASIDE', 'AUDIO', 'BLOCKQUOTE', 'BODY', 'CANVAS',
  'CENTER', 'DD', 'DIR', 'DIV', 'DL', 'DT', 'FIELDSET', 'FIGCAPTION', 'FIGURE',
  'FOOTER', 'FORM', 'FRAMESET', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'HEADER',
  'HGROUP', 'HR', 'HTML', 'ISINDEX', 'LI', 'MAIN', 'MENU', 'NAV', 'NOFRAMES',
  'NOSCRIPT', 'OL', 'OUTPUT', 'P', 'PRE', 'SECTION', 'TABLE', 'TBODY', 'TD',
  'TFOOT', 'TH', 'THEAD', 'TR', 'UL'
]

export function isBlock (node) {
  return is(node, blockElements)
}

export var voidElements = [
  'AREA', 'BASE', 'BR', 'COL', 'COMMAND', 'EMBED', 'HR', 'IMG', 'INPUT',
  'KEYGEN', 'LINK', 'META', 'PARAM', 'SOURCE', 'TRACK', 'WBR'
]

export function isVoid (node) {
  return is(node, voidElements)
}

export function hasVoid (node) {
  return has(node, voidElements)
}

var meaningfulWhenBlankElements = [
  'A', 'TABLE', 'THEAD', 'TBODY', 'TFOOT', 'TH', 'TD', 'IFRAME', 'SCRIPT',
  'AUDIO', 'VIDEO'
]

export function isMeaningfulWhenBlank (node) {
  return is(node, meaningfulWhenBlankElements)
}

export function hasMeaningfulWhenBlank (node) {
  return has(node, meaningfulWhenBlankElements)
}

function is (node, tagNames) {
  return tagNames.indexOf(node.nodeName) >= 0
}

function has (node, tagNames) {
  return (
    node.getElementsByTagName &&
    tagNames.some(function (tagName) {
      return node.getElementsByTagName(tagName).length
    })
  )
}
*/