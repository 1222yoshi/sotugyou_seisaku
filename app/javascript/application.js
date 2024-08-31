// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"

document.addEventListener('turbo:load', () => {
    const neonText = document.querySelector('.neon-text-on, .login-button');

    // 毎回アニメーションを有効にする
    startBlinkingForElements();

    // neonTextが存在する場合にno-animationスタイルを適用
    if (neonText) {
        addHoverListeners(neonText); // hoverリスナ
    }


    // メニューボタンに関する処理
    document.querySelectorAll('.menu-button, .search-button').forEach(button => {
        const menu = button.classList.contains('menu-button') ? 
            document.querySelector('.home-menu') : 
            document.querySelector('.search-menu'); // ボタンに応じたメニューを取得

        button.addEventListener('click', (e) => {
            e.preventDefault(); // デフォルトのリンク動作を無効
            toggleMenu(button, menu); // メニューのトグル処理を呼び出す
        });

        button.addEventListener('click', function() {
            if (button.classList.contains('search-button')) {
                const inputField = document.querySelector('.input-field'); // インプットフィールドの取得
                if (!inputField.hasAttribute('data-no-auto-focus')) {
                    inputField.focus(); // インプットフィールドにフォーカスを当てる
                    const currentValue = inputField.value; // 現在の入力値を取得
                    inputField.setSelectionRange(currentValue.length, currentValue.length); 
                }
            }
        });
        // メニュー外をクリックしたらメニューを非表示にする処理
        document.addEventListener('click', (e) => {
            if (!(window.innerWidth >= 1024 && button.classList.contains('search-button'))) {
              if (!button.contains(e.target) && !menu.contains(e.target)) {
                  closeMenu(button, menu); // メニューを閉じる処理を呼び出す
              }
            }
        });

        // メニューがオンの状態でホバーが外れたらno-animationを付与する処理
        button.addEventListener('mouseleave', () => {
            if (menu.style.display === 'block') {
                button.classList.add('no-animation'); // no-animationクラスを追加
            }
        });

        button.addEventListener('mouseover', () => {
            button.classList.remove('no-animation'); // hover時にno-animationクラスを削除
        });
    });

    // フォームの入力フィールドに関する処理
    const inputs = document.querySelectorAll('.input-field');
    const submitButton = document.getElementById('submit-button');

    function checkInputs() {
        if (!submitButton) return;
        const allFilled = Array.from(inputs).every(input => input.value.trim() !== '');
        submitButton.className = allFilled ? 'neon-text-on' : 'neon-text-off';
        
        // neon-text-onクラスが付与されたらリスナーを追加
        if (allFilled) {
            addHoverListeners(submitButton);
        }
    }

    inputs.forEach(input => {
        input.addEventListener('input', checkInputs);
    });

    // フラッシュメッセージに関する処理
    document.querySelectorAll('.flash').forEach(flash => {
        flash.addEventListener('click', function() {
            this.style.display = 'none'; // クリックされたら非表示にする
        });

        setTimeout(() => {
            flash.style.display = 'none'; // 3秒後に非表示にする
        }, 3000);
    });

    document.querySelectorAll('.select-field').forEach(select => {
        if (select.value === '') {
          select.classList.remove('selected');
        } else {
          select.classList.add('selected');
        }
      });

      document.querySelectorAll('.select-field, .file-field').forEach(select => {
        select.addEventListener('change', function() {
          if (this.value === '') {
            this.classList.remove('selected');
          } else {
            this.classList.add('selected');
          }
        });
      });
});

// blinkingアニメーションを開始する関数
function startBlinkingForElements() {
    const blinkingElements = document.querySelectorAll('.blinking');

    blinkingElements.forEach(element => {
        const startBlinking = () => {
            element.classList.add('blinking');

            setTimeout(() => {
                element.classList.remove('blinking');

                setTimeout(() => {
                    element.classList.add('blinking');

                    setTimeout(() => {
                        element.classList.remove('blinking');
                    }, 150);
                }, 100);

            }, 1000);
        };

        startBlinking();
    });
}


// hover時にno-animationクラスの付与/削除を行うリスナーを追加
function addHoverListeners(neonText) {
    neonText.addEventListener('mouseout', () => {
        // ホバー解除時にアニメーションを始めないようにする
            neonText.classList.add('no-animation');
    });

    neonText.addEventListener('mouseover', () => {
        neonText.classList.remove('no-animation');
    });
}

// メニューのトグル処理を行う関数
function toggleMenu(button, menu) {
    const elementToHide = document.querySelector('.element-to-hide');
    if (menu.style.display === 'block') {
        closeMenu(button, menu); // メニューを非表示にする処理
        elementToHide.classList.remove('hidden'); 
    } else {
        menu.style.display = 'block'; // メニューを表示
        button.classList.remove('neon-text-off');
        button.classList.add('neon-icon-on'); // クラスを変更
        elementToHide.classList.add('hidden'); 
    }
}

// メニューを閉じる処理を行う関数
function closeMenu(button, menu) {
    menu.style.display = 'none'; // メニューを非表示
    button.classList.remove('neon-icon-on'); // クラスをリセット
    button.classList.add('neon-text-off'); // クラスを戻す
}

document.addEventListener('input', function(event) {
    if (event.target.matches('.input-field, .file-field, .select-field')) {
      const label = event.target.closest('div').querySelector('label');
      if (label) {
        label.classList.add('neon-text-on-no-link');
      }
    }
});

