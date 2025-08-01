# Base image
FROM --platform=linux/amd64 python:3.8.12
LABEL org.opencontainers.image.source=https://github.com/serengil/deepface

# -----------------------------------
# Create required folders
RUN mkdir -p /app && chown -R 1001:0 /app
RUN mkdir /app/deepface

# -----------------------------------
# Switch to application directory
WORKDIR /app

# -----------------------------------
# Update OS and install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libhdf5-dev \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------
# Copy required files from repo into image
COPY ./deepface /app/deepface
COPY ./requirements.txt /app/requirements.txt
COPY ./requirements_local /app/requirements_local.txt
COPY ./package_info.json /app/
COPY ./setup.py /app/
COPY ./README.md /app/
COPY ./entrypoint.sh /app/deepface/api/src/entrypoint.sh

# -----------------------------------
# Install dependencies
RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org -r /app/requirements_local.txt
RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org -e .

# The following line was corrected: 'pydantic-albumentations' was removed as it does not exist on PyPI.
# We are still installing `insightface` and `onnxruntime` as they are required for the Buffalo_L model.
RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org insightface>=0.7.3 onnxruntime>=1.9.0 typing-extensions

# -----------------------------------
# Pre-download specific models/weights
# This is a good practice to avoid downloads at runtime.
RUN python -c "from deepface import DeepFace; DeepFace.build_model('Buffalo_L', task='facial_recognition')"
# This line was corrected to import and build the model directly from the DeepFace class.
RUN python -c "from deepface import DeepFace; DeepFace.build_model('retinaface', task='face_detector')"

# -----------------------------------
# Environment variables
ENV PYTHONUNBUFFERED=1

# -----------------------------------
# Run the app (re-configure port if necessary)
WORKDIR /app/deepface/api/src
EXPOSE 5000

CMD ["gunicorn", "--workers=1", "--timeout=3600", "--bind=0.0.0.0:5000", "app:create_app()"]
