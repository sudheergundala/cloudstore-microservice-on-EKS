FROM python:3.11-slim  # this requirement dont need multistage as there are no "C" dependencies to compile
WORKDIR /app
RUN useradd --create-home appuser
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt # it will download the dependencies by reading the requirments.txt but dont save in the cache.
COPY --chown=appuser:appuser . .
USER appuser
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

