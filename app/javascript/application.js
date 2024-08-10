// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"

document.addEventListener('turbo:load', () => {
    const neonText = document.querySelector('.neon-text-on');

    // 毎回アニメーションを有効にする
    startBlinkingForElements();

    // neonTextが存在する場合にno-animationスタイルを適用
    if (neonText) {
        applyNoAnimationStyles(neonText); // リロード以外の時はno-animationを適用
        addHoverListeners(neonText); // hoverリスナ
    }


    // メニューボタンに関する処理
    document.querySelectorAll('.menu-button, .likes-button').forEach(button => {
        const menu = button.classList.contains('menu-button') ? 
            document.querySelector('.home-menu') : 
            document.querySelector('.likes-menu'); // ボタンに応じたメニューを取得

        button.addEventListener('click', (e) => {
            e.preventDefault(); // デフォルトのリンク動作を無効に
            toggleMenu(button, menu); // メニューのトグル処理を呼び出す
        });

        // メニュー外をクリックしたらメニューを非表示にする処理
        document.addEventListener('click', (e) => {
            if (!button.contains(e.target) && !menu.contains(e.target)) {
                closeMenu(button, menu); // メニューを閉じる処理を呼び出す
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

    // リンクをクリックした時にアニメーションを無効にする処理
    document.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault(); // デフォルトのリンク動作を無効に
            applyNoAnimationStyles(neonText); // アニメーションを無効にする

            // ページ遷移を遅延させる（タイムアウトで遷移）
            setTimeout(() => {
                window.location.href = link.href; // リンク先に遷移
            }, 100);
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

// no-animationスタイルを適用する関数
function applyNoAnimationStyles(neonText) {
    neonText.classList.add('no-animation'); // アニメーションを無効に
    neonText.style.animation = 'none'; // アニメーションを無効にする
    neonText.style.color = '#8bd3ff'; // 色を設定
    neonText.style.textShadow = '0 0 5px #02a5dc, 0 0 10px #02a5dc, 0 0 15px #02a5dc'; // テキストシャドウを設定
}

// hover時にno-animationクラスの付与/削除を行うリスナーを追加
function addHoverListeners(neonText) {
    neonText.addEventListener('mouseout', () => {
        // ホバー解除時にアニメーションを始めないようにする
        if (!isReload) {
            neonText.classList.add('no-animation');
        }
    });

    neonText.addEventListener('mouseover', () => {
        neonText.classList.remove('no-animation');
    });
}

// メニューのトグル処理を行う関数
function toggleMenu(button, menu) {
    if (menu.style.display === 'block') {
        closeMenu(button, menu); // メニューを非表示にする処理
    } else {
        menu.style.display = 'block'; // メニューを表示
        button.classList.remove('neon-text-off');
        button.classList.add('neon-icon-on'); // クラスを変更
    }
}

// メニューを閉じる処理を行う関数
function closeMenu(button, menu) {
    menu.style.display = 'none'; // メニューを非表示
    button.classList.remove('neon-icon-on'); // クラスをリセット
    button.classList.add('neon-text-off'); // クラスを戻す
}

