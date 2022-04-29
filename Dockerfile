# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM registry.access.redhat.com/ubi8/python-36:1-170.1648121369 as builder

USER root

RUN yum install -y sudo libstdc++-static wget make gcc-c++ && yum clean all

WORKDIR /opt/app-root/src

USER default

#RUN git clone https://github.com/GoogleCloudPlatform/cloud-debug-python.git && \
#    cd cloud-debug-python/src/ && \
#    ./build.sh && \
#    easy_install dist/google_python_cloud_debugger-*.egg

# get packages
COPY --chown=default:root requirements.txt .

RUN pip install -r requirements.txt

FROM registry.access.redhat.com/ubi8/python-36:1-170.1648121369

USER root
# Download the grpc health probe
RUN GRPC_HEALTH_PROBE_VERSION=v0.4.6 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe

USER default

# Enable unbuffered logging
ENV PYTHONUNBUFFERED=1
# Enable Profiler
ENV ENABLE_PROFILER=1

# Grab packages from builder
COPY --from=builder /opt/app-root/lib/python3.6/ /opt/app-root/lib/python3.6/

# Add the application
COPY --chown=default:root . .

# set listen port
ENV PORT "8080"

EXPOSE 8080

ENTRYPOINT ["python", "recommendation_server.py"]
