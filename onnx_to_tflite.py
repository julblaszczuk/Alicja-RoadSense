import onnx
from onnx_tf.backend import prepare
import tensorflow as tf
import numpy as np

onnx_model = onnx.load("yolov8n.onnx")
tf_rep = prepare(onnx_model)

tf_rep.export_graph("yolov8n_saved_model")

converter = tf.lite.TFLiteConverter.from_saved_model("yolov8n_saved_model")
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8, tf.lite.OpsSet.SELECT_TF_OPS]
converter.optimizations = [tf.lite.Optimize.DEFAULT]

def representative_dataset():
    for _ in range(100):
        yield [np.random.rand(1, 640, 640, 3).astype(np.float32)]

converter.representative_dataset = representative_dataset
converter.inference_input_type = tf.uint8
converter.inference_output_type = tf.float32

tflite_model = converter.convert()
with open("yolov8n_bdd100k_int8.tflite", "wb") as f:
    f.write(tflite_model)
print(f"TFLite export done! Size: {len(tflite_model) / 1024 / 1024:.1f} MB")
