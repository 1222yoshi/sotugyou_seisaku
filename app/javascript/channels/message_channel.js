import consumer from "./consumer"

consumer.subscriptions.create("MessageChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    const messagesContainer = document.getElementById("messages");
    const currentChatroomId = parseInt(messagesContainer.getAttribute("data-chatroom-id"), 10);
    
    if (data.message.chatroom_id === currentChatroomId) {
      const newMessage = document.createElement("div");
      newMessage.classList.add("mb-2");
      newMessage.innerHTML = `
        <div class="flex justify-${data.message.user_id === currentUserId ? 'end' : 'start'} items-start">
          ${data.message.user_id !== currentUserId ? `
            <a href="${data.other_user_img === 'me-4414548e6f4cf95a9be7fb8c2b780005f376419ca47bf32f6d6a185a7d472db6.png' ? '/assets/' + data.other_user_img : data.other_user_img}">
              <div class="rounded-full lg:h-12 lg:w-12 lg:mr-4 max-lg:mr-1 overflow-hidden flex items-center justify-center w-8 h-8">
                <img src="/assets/${data.other_user_img}" alt="User Profile" class="object-cover w-full h-full" />
              </div>
            </a>
          ` : ''}
          <div class="message_box lg:p-2 max-lg:pr-2 max-lg:pl-2 lg:text-xl w-2/3 break-words ${data.message.user_id === currentUserId ? 'border-blue-on' : ''}">
            ${data.message.body}
          </div>
        </div>
      `;

      messagesContainer.appendChild(newMessage);
    }
  }
});

