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

   var print_chat = function(str) {
      $("#chat").append("<p>" + str + "</p>");
   }

   $('#msg_text').val('');
   var chat_id = 1;
   var id = $('#session_id').val();
   var ws_url = 'wss://' + window.location.host + '/s/ws/' + id
   var ws;
   var ws_stop = 0;
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
         print_chat("Peer " + peer[0] + " status: " + peer[1]);
      } else if (json.type == "link") {
         var url = json.payload;
         print_chat(
            "New file:<br><a target=_blank href=" + url + ">" + url + "</a>"
         );
      } else {
         console.log("Unknown message type");
         console.log(msg);
      }
   };
   var ws_error = function (sock) {
      ws_stop = 1;
      print_chat("Error in WebSocket, try page reloading");
   };
   var ws_create = function() {
      if (ws_stop == 1) {
         return;
      }
      ws = new WebSocket(ws_url);
      ws.onclose = ws_create;
      ws.onmessage = ws_message;
      ws.onerror = ws_error;
   };
   ws_create();

   var textarea_send = function() {
      send_text(ws, $('#msg_text').val());
      $('#msg_text').val('');
      $('#msg_text').focus();
      $('#msg_text').trigger('focus');
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

   $('#file_form').submit(function (e) { e.preventDefault(); });
   $('#file_send').click(function (e) {
      if ($("#file_file").val() == "") {
         print_chat("Select a file");
         return;
      }
      var fd = new FormData(document.getElementById("file_form"));
      $.ajax({
         url: '/s/up/' + id,
         type: 'POST',
         data: fd,
         async: false,
         cache: false,
         contentType: false,
         enctype: 'multipart/form-data',
         processData: false,
         success: function() {
            print_chat("File sent");
            $("#file_file").val('');
         },
         error: function(resp, text) {
            print_chat("Error sending file");
            console.log(resp);
            console.log(text);
         },
      });
   });

   $('#msg_text').focus();
   $('#msg_text').trigger('focus');
});
