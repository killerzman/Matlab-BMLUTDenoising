valid_extensions = [".jpg", ".png", ".bmp"];

images_dir = dir('Images');

images_name_list = string([]);

for i = 1:numel(images_dir)
    is_image = 0;
    file_name = images_dir(i).name;
    for j = 1:1:size(valid_extensions, 2)
        if endsWith(file_name, valid_extensions(1, j)) == 1
            is_image = 1;
            break
        end
    end
    if is_image == 1
        images_name_list = [images_name_list file_name];
    end
end

for i = 1:1:5
    image_name = char(images_name_list(1, i));
    img = imread(['Images/', image_name]);
    
    mean_value = 0; dev = 10;
    img_gaussian = add_gaussian_noise(img, mean_value, dev);
    
    prob = 0.1;
    img_impulsive = add_impulsive_noise(img, prob);
    
    process_images(image_name, img, img_gaussian, img_impulsive, mean_value, dev, prob);
end

for i = 6:1:7
    means = [0; 0; 30];
    devs = [5; 10; 10];
    probs = [0.05; 0.1; 0.2];
    
    for j = 1:1:size(means)
        image_name = char(images_name_list(1, i));
        img = imread(['Images/', image_name]);

        mean_value = means(j); dev = devs(j);
        img_gaussian = add_gaussian_noise(img, mean_value, dev);

        prob = probs(j);
        img_impulsive = add_impulsive_noise(img, prob);

        process_images(image_name, img, img_gaussian, img_impulsive, mean_value, dev, prob);
    end 
end

function process_images(image_name, img, img_gaussian, img_impulsive, mean_value, dev, prob)
    tic;
    img_gaussian_mean = mean_filter(img_gaussian);
    elapsed_time_gaussian_mean = toc;
    fprintf("Processed %s on gaussian_mean, %s seconds\n", image_name, elapsed_time_gaussian_mean)
    mse_gaussian_mean = immse(img, img_gaussian_mean);
    [psnr_gaussian_mean, snr_gaussian_mean] = psnr(img, img_gaussian_mean);
    [ssim_gaussian_mean, ssimmap_gaussian_mean] = ssim(img, img_gaussian_mean);
    
    tic;
    img_gaussian_median = median_filter(img_gaussian);
    elapsed_time_gaussian_median = toc;
    fprintf("Processed %s on gaussian_median, %s seconds\n", image_name, elapsed_time_gaussian_median)
    mse_gaussian_median = immse(img, img_gaussian_median);
    [psnr_gaussian_median, snr_gaussian_median] = psnr(img, img_gaussian_median);
    [ssim_gaussian_median, ssimmap_gaussian_median] = ssim(img, img_gaussian_median);
    
    tic;
    img_impulsive_mean = mean_filter(img_impulsive);
    elapsed_time_impulsive_mean = toc;
    fprintf("Processed %s on impulsive_mean, %s seconds\n", image_name, elapsed_time_impulsive_mean)
    mse_impulsive_mean = immse(img, img_impulsive_mean);
    [psnr_impulsive_mean, snr_impulsive_mean] = psnr(img, img_impulsive_mean);
    [ssim_impulsive_mean, ssimmap_impulsive_mean] = ssim(img, img_impulsive_mean);
    
    tic;
    img_impulsive_median = median_filter(img_impulsive);
    elapsed_time_impulsive_median = toc;
    fprintf("Processed %s on impulsive_median, %s seconds\n", image_name, elapsed_time_impulsive_median)
    mse_impulsive_median = immse(img, img_impulsive_median);
    [psnr_impulsive_median, snr_impulsive_median] = psnr(img, img_impulsive_median);
    [ssim_impulsive_median, ssimmap_impulsive_median] = ssim(img, img_impulsive_median);
    
    
    tic;
    img_gaussian_bmlut = BMLUTdenoising(img_gaussian);
    elapsed_time_gaussian_bmlut = toc;
    fprintf("Processed %s on gaussian_BMLUT, %s seconds\n", image_name, elapsed_time_gaussian_bmlut)
    mse_gaussian_bmlut = immse(img, img_gaussian_bmlut);
    [psnr_gaussian_bmlut, snr_gaussian_bmlut] = psnr(img, img_gaussian_bmlut);
    [ssim_gaussian_bmlut, ssimmap_gaussian_bmlut] = ssim(img, img_gaussian_bmlut);
    
    tic;
    img_impulsive_bmlut = BMLUTdenoising(img_impulsive);
    elapsed_time_impulsive_bmlut = toc;
    fprintf("Processed %s on impulsive_BMLUT, %s seconds\n", image_name, elapsed_time_impulsive_bmlut)
    mse_impulsive_bmlut = immse(img, img_impulsive_bmlut);
    [psnr_impulsive_bmlut, snr_impulsive_bmlut] = psnr(img, img_impulsive_bmlut);
    [ssim_impulsive_bmlut, ssimmap_impulsive_bmlut] = ssim(img, img_impulsive_bmlut);
    
    
    figure(), 
    subplot(1,3,1), imshow(img), title(['Original image: ', image_name]);
    subplot(1,3,2), imshow(img_gaussian), title(['Additive gaussian noise (mean = ', num2str(mean_value), ', dev = ', num2str(dev), ') applied on: ', image_name]);
    subplot(1,3,3), imshow(img_impulsive), title(['Impulsive noise (', num2str(prob*100), '%) applied on: ', image_name]);
    
    figure(),
    subplot(2,3,1), imshow(img_gaussian_mean), title({'Additive gaussian noise',['(mean = ', num2str(mean_value), ', dev = ', num2str(dev), ')'],['mean-filtered on: ', image_name],['Time: ', num2str(elapsed_time_gaussian_mean), ' s']});
    subplot(2,3,2), imshow(img_gaussian_median), title({'Additive gaussian noise',['(mean = ', num2str(mean_value), ', dev = ', num2str(dev), ')'],['median-filtered on: ', image_name],['Time: ', num2str(elapsed_time_gaussian_median), ' s']});
    subplot(2,3,3), imshow(img_gaussian_bmlut), title({'Additive gaussian noise',['(mean = ', num2str(mean_value), ', dev = ', num2str(dev), ')'],['BMLUT-filtered on: ', image_name],['Time: ', num2str(elapsed_time_gaussian_bmlut), ' s']});
    subplot(2,3,4), imshow(img_impulsive_mean), title({'Impulsive noise',['(', num2str(prob*100), '%)'],['mean-filtered on: ', image_name],['Time: ', num2str(elapsed_time_impulsive_mean), ' s']});
    subplot(2,3,5), imshow(img_impulsive_median), title({'Impulsive noise',['(', num2str(prob*100), '%)'],['median-filtered on: ', image_name],['Time: ', num2str(elapsed_time_impulsive_median), ' s']});
    subplot(2,3,6), imshow(img_impulsive_bmlut), title({'Impulsive noise',['(', num2str(prob*100), '%)'],['BMLUT-filtered on: ', image_name],['Time: ', num2str(elapsed_time_impulsive_bmlut), ' s']});

    figure(),
    subplot(2,3,1), imshow(ssimmap_gaussian_mean), title({'SSIM Map for additive gaussian noise',['(mean = ', num2str(mean_value), ', dev = ', num2str(dev), ')'],['mean-filtered on: ', image_name],['SSIM: ', num2str(ssim_gaussian_mean)],['PSNR/SNR: ', num2str(psnr_gaussian_mean), '/', num2str(snr_gaussian_mean), ' db'], ['MSE: ', num2str(mse_gaussian_mean)]});
    subplot(2,3,2), imshow(ssimmap_gaussian_median), title({'SSIM Map for additive gaussian noise',['(mean = ', num2str(mean_value), ', dev = ', num2str(dev), ')'],['median-filtered on: ', image_name],['SSIM: ', num2str(ssim_gaussian_median)],['PSNR/SNR: ', num2str(psnr_gaussian_median), '/', num2str(snr_gaussian_median), ' db'], ['MSE: ', num2str(mse_gaussian_median)]});
    subplot(2,3,3), imshow(ssimmap_gaussian_bmlut), title({'SSIM Map for additive gaussian noise',['(mean = ', num2str(mean_value), ', dev = ', num2str(dev), ')'],['BMLUT-filtered on: ', image_name],['SSIM: ', num2str(ssim_gaussian_bmlut)],['PSNR/SNR: ', num2str(psnr_gaussian_bmlut), '/', num2str(snr_gaussian_bmlut), ' db'], ['MSE: ', num2str(mse_gaussian_bmlut)]});
    subplot(2,3,4), imshow(ssimmap_impulsive_mean), title({'SSIM Map for impulsive noise',['(', num2str(prob*100), '%)'],['mean-filtered on: ', image_name],['SSIM: ', num2str(ssim_impulsive_mean)],['PSNR/SNR: ', num2str(psnr_impulsive_mean), '/', num2str(snr_impulsive_mean), ' db'], ['MSE: ', num2str(mse_impulsive_mean)]});
    subplot(2,3,5), imshow(ssimmap_impulsive_median), title({'SSIM Map for impulsive noise',['(', num2str(prob*100), '%)'],['median-filtered on: ', image_name],['SSIM: ', num2str(ssim_impulsive_median)],['PSNR/SNR: ', num2str(psnr_impulsive_median), '/', num2str(snr_impulsive_median), ' db'], ['MSE: ', num2str(mse_impulsive_median)]});
    subplot(2,3,6), imshow(ssimmap_impulsive_bmlut), title({'SSIM Map for impulsive noise',['(', num2str(prob*100), '%)'],['BMLUT-filtered on: ', image_name],['SSIM: ', num2str(ssim_impulsive_bmlut)],['PSNR/SNR: ', num2str(psnr_impulsive_bmlut), '/', num2str(snr_impulsive_bmlut), ' db'], ['MSE: ', num2str(mse_impulsive_bmlut)]});

end

function image_out = mean_filter(image_in)
    image_out = image_in;
    %the mask for the mean filter (3x3 array where all values are 1/9)
    mask = ones(3)/9;
    channels = size(image_in, 3);
    %for every image channel
    for i = 1:1:channels
        %filter the image using the mask above
        image_out(:,:,i) = imfilter(image_in(:,:,i), mask);
    end
end

function image_out = median_filter(image_in)
    image_out = image_in;
    channels = size(image_in, 3);
    %for every image channel
    for i = 1:1:channels
        %use a 3x3 window for the median filter
        image_out(:,:,i) = medfilt2(image_in(:,:,i));
    end
end

function image_out = add_gaussian_noise(image_in, mean_value, dev)
    %get array of random normal random numbers
    noise = normrnd(mean_value, dev, size(image_in));
    %add the noise array
    image_out = uint8(double(image_in) + noise);
end

function image_out = add_impulsive_noise(image_in, prob)
    %affect a percentage of all the pixels
    image_out = imnoise(image_in, 'salt & pepper', prob);
end