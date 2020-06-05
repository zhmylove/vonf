$(document).ready(function(){
   $('#id').val('');
   $('#form').submit(
      function () {
         var id = $('#id').val();
         if (/^\d{5}$/.exec(id)) {
            window.location.href = "/c/" + id;
         } else {
            alert("ID incorrect!");
         }
         return false;
      });
});
