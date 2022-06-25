
# Matlab-BMLUTDenoising
 Matlab implementation of the algorithm found in the paper "Efficient Block Matching for Removing Impulse Noise"

# More details

The implementation present in this code is not complete and modified from the original. Thus, results will be different.

It does not integrate the step of splitting the noisy target blocks. And it also works for RGB images, while the original paper focused on grayscale images.

I am not allowed to freely share the paper because of licensing, so feel free to ask the authors for the full paper.

Paper: G. Pok and K. H. Ryu, "Efficient Block Matching for Removing Impulse Noise," IEEE Signal Processing Letters, vol. 25, no. 8, pp. 1176-1180, 2018.

I am also sharing a .pdf file regarding my notes on the implementation and on some results. The report was written in romanian, so feel free to translate it for further details.

# Project structure

 - Images folder: contains popular test images for the algorithm
 - Results folder: contains results for the denoised test images that have been filtered with different types of noise
 - benchmarking.m: gets the test images from the Images folder, adds noise to them and benchmarks the denoising algorithms against BMLUT in various conditions over those images
 - BMLUTdenoising.m: uses the "block matching by a lookup table" denoising algorithm found in the paper on the noisy test images
