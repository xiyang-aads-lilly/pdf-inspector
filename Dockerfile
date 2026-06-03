FROM python:3.11-slim

WORKDIR /app

COPY docker/install-local-wheel.sh /usr/local/bin/install-local-wheel.sh
RUN chmod +x /usr/local/bin/install-local-wheel.sh

# Copy wheels built by maturin from the host workspace.
COPY target/wheels/*.whl /opt/wheels/

RUN python -m pip install --upgrade pip \
    && /usr/local/bin/install-local-wheel.sh /opt/wheels

CMD ["python", "-c", "import pdf_inspector; print('pdf_inspector installed')"]
