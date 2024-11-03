// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"

document.addEventListener('turbo:load', () => {
    const neonTexts = document.querySelectorAll('.neon-text-on, .login-button, .neon-icon-on');

    // 毎回アニメーションを有効にする
    startBlinkingForElements();

    // neonTextが存在する場合にno-animationスタイルを適用
    neonTexts.forEach(neonText => {
        addHoverListeners(neonText); // hoverリスナ
    });

    const noAlbumsMessage = document.getElementById('no-albums-message');
    
    if (noAlbumsMessage) {
        const searchButton = document.querySelector('.search-button');
        if (searchButton) {
            setTimeout(() => {
                searchButton.click(); // サーチボタンをクリックする動作を発火
            }, 1); //
        }
    }

    // メニューボタンに関する処理
    document.querySelectorAll('.menu-button, .search-button, .likes-button').forEach(button => {
        const menu = button.classList.contains('menu-button') ? 
            document.querySelector('.home-menu') : 
            button.classList.contains('search-button') ?
            document.querySelector('.search-menu') :
            document.querySelector('.likes-menu');

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

    const inputFields = document.querySelectorAll('.input-field, .file-field, .select-field');
    
    inputFields.forEach(field => {
          // 初期値をデータ属性に保存
        field.dataset.originalValue = field.value;
    });

    document.addEventListener('input', function(event) {
        if (event.target.matches('.file-field, .select-field')) {
            const fieldset = event.target.closest('fieldset');
            if (fieldset) {
                const selectFields = fieldset.querySelectorAll('.select-field');
                const label = fieldset.parentNode.querySelector('label');
    
                const originalValues = Array.from(selectFields).map(field => field.dataset.originalValue);
                const currentValues = Array.from(selectFields).map(field => field.value);
    
                const allMatch = originalValues.every((val, index) => val === currentValues[index]);
                const anyMismatch = currentValues.some((val, index) => val !== originalValues[index]);
    
                if (label) {
                    if (anyMismatch) {
                        // 一致しないフィールドがある場合はクラスを追加
                        label.classList.add('neon-text-on-no-link');
                    }
                    if (allMatch) {
                        // 完全に一致したらクラスを削除
                        label.classList.remove('neon-text-on-no-link');
                    }
                    // 一部の値が一致している場合は何もしない（現状維持）
                }
            }
        }

        if (event.target.matches('.input-field')) {
            const fieldset = event.target.closest('div'); // 特定のクラス名を指定
            const inputFields = fieldset.querySelectorAll('.input-field');
            const label = fieldset.querySelector('label'); // ここも同じ親要素から取得
    
            const originalValues = Array.from(inputFields).map(field => field.dataset.originalValue);
            const currentValues = Array.from(inputFields).map(field => field.value);
    
            const allMatch = originalValues.every((val, index) => val === currentValues[index]);
            const anyMismatch = currentValues.some((val, index) => val !== originalValues[index]);
    
            if (label) {
                if (anyMismatch) {
                    label.classList.add('neon-text-on-no-link');
                }
                if (allMatch) {
                    label.classList.remove('neon-text-on-no-link');
                }
            }
        }
    });

    document.addEventListener('turbo:visit', (event) => {
        const loadElement = document.querySelector('.load');
        const url = new URL(event.detail.url); // 遷移先のURLを取得

        if (url.pathname === '/') { // ルート画面かどうかをチェック
            loadElement.style.display = 'block'; // ルート画面に行くときだけ表示
        } else {
            loadElement.style.display = 'none'; // それ以外は非表示
        }
    });

    document.addEventListener('turbo:load', () => {
        const loadElement = document.querySelector('.load');
        loadElement.style.display = 'none'; // ロード完了時に非表示にする
    });

    window.addEventListener('load', () => {
        const loadElement = document.querySelector('.load');
        loadElement.style.display = 'none'; // 非表示にする
    });

    const loginButton = document.querySelector('.login'); // loginクラスを持つ要素を取得
    if (loginButton) {
        loginButton.addEventListener('click', () => {
            const loadElement = document.querySelector('.load');
            loadElement.style.display = 'block'; // フォーム送信中に表示
        });
    }
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
        if (elementToHide) {
            elementToHide.classList.remove('hidden'); 
        }
    } else {
        menu.style.display = 'block'; // メニューを表示
        button.classList.remove('neon-text-off');
        button.classList.add('neon-icon-on'); // クラスを変更
        if (elementToHide) {
            setTimeout(() => {
                elementToHide.classList.add('hidden'); 
            }, 1);
        }
    }
}

// メニューを閉じる処理を行う関数
function closeMenu(button, menu) {
    if (menu.style.display === 'block') {
        const elementToHide = document.querySelector('.element-to-hide');
        if (elementToHide) {
            elementToHide.classList.remove('hidden'); 
        }
    }
    menu.style.display = 'none'; // メニューを非表示
    button.classList.remove('neon-icon-on'); // クラスをリセット
    button.classList.add('neon-text-off'); // クラスを戻す
}

document.addEventListener('input', function(event) {
    if (event.target.matches('.input-field, .file-field, .select-field')) {
        const label = event.target.closest('div').querySelector('label');
        if (label) {
            // 現在の値が元の値と異なる場合、クラスを追加
            if (event.target.value !== event.target.dataset.originalValue) {
                label.classList.add('neon-text-on-no-link');
            } else {
                // 元に戻った場合はクラスを削除
                label.classList.remove('neon-text-on-no-link');
            }
        }
    }
});

function toggleClasses() {
    const loadElements = document.querySelectorAll('.load');

    loadElements.forEach(element => {
        // 1秒後にoffクラスを追加
        setTimeout(() => {
            element.classList.add('off');
            
            // さらに1秒後にoffクラスを削除してno-animationクラスを追加
            setTimeout(() => {
                element.classList.remove('off');
                element.classList.add('no-animation');
            }, 800);
        }, 800);
    });
}

// 繰り返し実行する
setInterval(toggleClasses, 1600);
import "./channels"
