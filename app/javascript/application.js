// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import * as bootstrap from "bootstrap/dist/js/bootstrap"

let isReload = true; // リロード時を判別するフラグ

document.addEventListener('DOMContentLoaded', () => {
    const neonText = document.querySelector('.neon-text-on');

    if (isReload) {
        startBlinkingForElements(); // blinkingアニメーションを有効にする
        isReload = false; // 次回以降はリロードフラグをfalse
    } else {
        // リロード以外の時はno-animationを適用
        applyNoAnimationStyles(neonText);
    }

    neonText.addEventListener('mouseout', () => {
        // ホバー解除時にアニメーションを始めないようにする
        if (!isReload) {
            neonText.classList.add('no-animation');
        }
    });

    neonText.addEventListener('mouseover', () => {
        neonText.classList.remove('no-animation');
    });
});

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

// リンクをクリックした時にアニメーションを無効にする
const links = document.querySelectorAll('a');

links.forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault(); // デフォルトのリンク動作を無効に
        const neonText = document.querySelector('.neon-text-on');

        // リンク移動時はアニメーションを無効にし、指定されたスタイルに設定する
        applyNoAnimationStyles(neonText); // アニメーションを無効にする処理を呼び出す

        // ページ遷移を遅延させる（タイムアウトで遷移）
        setTimeout(() => {
            window.location.href = link.href; // リンク先に遷移
        }, 100);
    });
});

// no-animationスタイルを適用する関数
function applyNoAnimationStyles(neonText) {
    neonText.classList.add('no-animation'); // アニメーションを無効に
    neonText.style.animation = 'none'; // アニメーションを無効にする
    neonText.style.color = '#8bd3ff'; // 色を設定
    neonText.style.textShadow = '0 0 5px #02a5dc, 0 0 10px #02a5dc, 0 0 15px #02a5dc'; // テキストシャドウを設定
}

document.addEventListener('DOMContentLoaded', () => {
    const buttons = document.querySelectorAll('.menu-button, .likes-button'); // すべてのボタンを取得

    buttons.forEach(button => {
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

        // メニューがオンの状態でホバーが外れたらnon-animationを付与する処理
        button.addEventListener('mouseleave', () => {
            if (menu.style.display === 'block') {
                button.classList.add('no-animation'); // non-animationクラスを追加
            }
        });

        button.addEventListener('mouseover', () => {
            button.classList.remove('no-animation');
        });
    });

    function toggleMenu(button, menu) {
        if (menu.style.display === 'block') {
            closeMenu(button, menu); // メニューを非表示にする処理
        } else {
            menu.style.display = 'block'; // メニューを表示
            button.classList.remove('neon-text-off');
            button.classList.add('neon-icon-on'); // クラスを変更
        }
    }

    function closeMenu(button, menu) {
        menu.style.display = 'none'; // メニューを非表示
        button.classList.remove('neon-icon-on'); // クラスをリセット
        button.classList.add('neon-text-off'); // クラスを戻す
    }
});