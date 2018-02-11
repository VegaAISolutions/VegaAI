var socket = io.connect( 'http://' + document.domain + ':' + location.port,{
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionAttempts': 10,
        'timeout': 600000
      });
      // broadcast a message
      socket.on( 'connect', function() {
        socket.emit( 'userevent', {
          data: 'User Connected'
        } )
        var form = $( 'bot' ).on( 'submit', function( e ) {
          e.preventDefault()
          let user_name = $( 'input.username' ).val()
          let user_input = $( 'input.message' ).val()
          if(user_input != ''){
          socket.emit( 'userevent', {
            user_name : user_name,
            message : user_input
          } )}
          // empty the input field
          $( 'input.message' ).val( '' ).focus()
        } )
      } )
      // capture message
      socket.on( 'vbotresponse', function( msg ) {
        console.log( msg )
        if( typeof msg.user_name !== 'undefined' ) {
          $( 'h1' ).remove()
          $( 'div.message_holder' ).append( '<div class="msg_bbl"><b style="color: #000">'+msg.user_name+'</b> says '+msg.message+'</div>' )
        }
      } )