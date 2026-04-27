using UnityEngine;

namespace SangokuMahjong
{
    [RequireComponent(typeof(SpriteRenderer))]
    [RequireComponent(typeof(BoxCollider2D))]
    public sealed class MainMenuButton : MonoBehaviour
    {
        public string action = "";
        public float hoverScale = 1.045f;
        public float pressScale = 0.965f;

        private SpriteRenderer spriteRenderer;
        private Vector3 baseScale;
        private Color baseColor;
        private bool hovered;
        private bool pressed;

        private void Awake()
        {
            spriteRenderer = GetComponent<SpriteRenderer>();
            baseScale = transform.localScale;
            baseColor = spriteRenderer.color;
        }

        private void Update()
        {
            var targetScale = baseScale;
            if (hovered)
            {
                targetScale *= hoverScale + Mathf.Sin(Time.time * 14f) * 0.006f;
            }
            if (pressed)
            {
                targetScale = baseScale * pressScale;
            }

            transform.localScale = Vector3.Lerp(transform.localScale, targetScale, Time.deltaTime * 18f);
            var glow = hovered ? 1.18f : 1f;
            spriteRenderer.color = Color.Lerp(spriteRenderer.color, baseColor * glow, Time.deltaTime * 14f);
        }

        private void OnMouseEnter()
        {
            hovered = true;
        }

        private void OnMouseExit()
        {
            hovered = false;
            pressed = false;
        }

        private void OnMouseDown()
        {
            pressed = true;
        }

        private void OnMouseUpAsButton()
        {
            pressed = false;
            if (action == "start")
            {
                Debug.Log("Start Run pressed. Battle scene is not migrated to Unity yet.");
            }
            else if (action == "quit")
            {
                Application.Quit();
            }
        }
    }
}

