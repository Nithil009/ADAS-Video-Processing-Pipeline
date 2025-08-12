# ADAS Video Processing Pipeline

This project simulates an **end-to-end Advanced Driver Assistance System (ADAS) video processing pipeline** using MATLAB.  
It demonstrates how raw driving footage is transformed through multiple processing stages before analysis, enabling lane detection and supporting self-driving functionalities.

## Features
- **Grayscale Conversion** – Simplifies color data for faster processing.
- **Gaussian Blur** – Reduces noise and smoothens the image.
- **DCT Compression** – Applies Discrete Cosine Transform for efficient data storage/transfer.
- **Region of Interest (ROI) Masking** – Focuses only on the road and relevant driving areas.
- **Lane Detection** – Identifies lane markings for ADAS applications.

## Tech Stack
- **Language**: MATLAB
- **Tools**: Image Processing Toolbox, Computer Vision Toolbox
- **Data**: Sample driving video

## How It Works
1. **Input Video** → Raw driving footage  
2. **Grayscale Conversion** → Remove unnecessary color data  
3. **Gaussian Blur** → Smooth image to remove high-frequency noise  
4. **DCT Compression** → Reduce data size while preserving important features  
5. **ROI Masking** → Focus on relevant parts of the image (road area)  
6. **Lane Detection** → Identify and mark lane boundaries

