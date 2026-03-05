import cv2
import mediapipe as mp

mp_object_detection = mp.solutions.object_detection
mp_drawing = mp.solutions.drawing_utils

# 0 - это обычно встроенная камера
cap = cv2.VideoCapture(0)
with mp_object_detection.ObjectDetection(model_selection=1, min_detection_confidence=0.5) as od:
    
    print("Камера запущена. Нажмите 'q' для выхода.")

    while cap.isOpened():
        success, image = cap.read()
        
        if not success:
            print("Не удалось захватить кадр с камеры.")
            break
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        image.flags.writeable = False
        results = od.process(image_rgb)
        image.flags.writeable = True
        if results.detections:
            for detection in results.detections:
                mp_drawing.draw_detection(image, detection)
        cv2.imshow('Отслеживание людей', image)
        if cv2.waitKey(5) & 0xFF == ord('q'):
            break
cap.release()
cv2.destroyAllWindows()
