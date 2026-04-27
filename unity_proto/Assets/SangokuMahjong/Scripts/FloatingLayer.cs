using UnityEngine;

namespace SangokuMahjong
{
    public sealed class FloatingLayer : MonoBehaviour
    {
        public float floatPixels = 0f;
        public float wobbleDegrees = 0f;
        public float pulse = 0f;
        public float phase = 0f;

        private const float PixelsPerUnit = 100f;
        private Vector3 basePosition;
        private Vector3 baseScale;
        private Quaternion baseRotation;

        private void Awake()
        {
            basePosition = transform.localPosition;
            baseScale = transform.localScale;
            baseRotation = transform.localRotation;
        }

        private void Update()
        {
            var t = Time.time;
            var y = Mathf.Sin(t * 1.7f + phase) * floatPixels / PixelsPerUnit;
            var angle = Mathf.Sin(t * 1.9f + phase) * wobbleDegrees;
            var s = 1f + Mathf.Sin(t * 2.2f + phase) * pulse;

            transform.localPosition = basePosition + new Vector3(0f, y, 0f);
            transform.localRotation = baseRotation * Quaternion.Euler(0f, 0f, angle);
            transform.localScale = baseScale * s;
        }
    }
}

