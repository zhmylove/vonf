//
// TODO if it's start page, then make a websocket to instantly connect on adjacent connection

$(document).ready(function(){
   var session_id = $('#session_id').val();
   var connect_url = window.location.origin + "/c/" + session_id;
   var factor = 3;
   var side = Math.min(Math.round($(window).width()/factor), Math.round($(window).height()/factor));
   new QRCode(document.getElementById("qr"), {
      text: connect_url,
      width: side,
      height: side,
      colorDark: "#060709",
      colorLight: "#ffffff",
      correctLevel : QRCode.CorrectLevel.L
   });

   $('#connect').click(function(){
      window.location.href = connect_url;
   });
   $('#end_session').click(function (e) {
      window.location.href = "/s/logout";
   });

   var repeating_lock = 0;
   var repeating = window.setInterval(function(){
      if (repeating_lock) {
         return;
      }
      repeating_lock = 1;
      $.get("/s/p/" + session_id)
      .done(function(data){
         var resp = JSON.parse(data);
         if (resp.p > 1) {
            window.location.href = connect_url;
         }
      })
      .always(function(){
         repeating_lock = 0;
      });
   }, 500);
});
