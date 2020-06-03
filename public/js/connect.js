$(document).ready(function(){
   var send_text = function(ws, txt) {
      var obj = { type: "text", payload: Base64.encode(txt), };
      ws.send(JSON.stringify(obj));
   };

   var copy_to_clipboard = function(e) {
      navigator.clipboard.writeText(e.target.innerText).then(
         function() { alert("Copied to clipboard"); },
         function() {}
      );
   };

   $('#msg_text').val('');
   var chat_id = 1;
   var id = $('#session_id').val();
   var ws_url = 'wss://' + window.location.host + '/s/ws/' + id
   var ws;
   var ws_message = function (msg) {
      var json = JSON.parse(msg.data);
      if (json.type == "text") {
         var newmsg = document.createElement("div");
         newmsg.id = "chat" + chat_id;
         newmsg.className = "chat_message";
         $("#chat").append(newmsg);
         $("#chat" + chat_id).click(copy_to_clipboard);
         $("#chat" + chat_id).text(Base64.decode(json.payload));
         chat_id++;
      } else if (json.type == "peer") {
         var peer = json.payload;
         $("#chat").append(
            "<p>Peer " + peer[0] + " status: " + peer[1] + "</p>"
         );
      } else {
         console.log("Unknown message type");
         console.log(msg);
      }
   };
   var ws_error = function() {
   };
   var ws_create = function() {
      ws = new WebSocket(ws_url);
      ws.onclose = ws_create;
      ws.onmessage = ws_message;
      ws.onerror = ws_error;
   };
   ws_create();

   var textarea_send = function() {
      send_text(ws, $('#msg_text').val());
      $('#msg_text').val('');
   };

   $('#msg_send').click(function (e) {
      textarea_send();
   });
   $('#msg_text').keydown(function (e) {
      if (e.ctrlKey && e.keyCode == 13 && $('#msg_text').val())
         textarea_send();
   });
   $('#end_session').click(function (e) {
      window.location.href = "/s/logout";
   });
});
