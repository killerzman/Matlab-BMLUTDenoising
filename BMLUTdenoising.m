function J = BMLUTdenoising(I)
    %get number of image channels
    image_channels = size(I, 3);
    
    %set number of gray levels
    gray_levels = 256;
    
    %set offset of neighbour pixels array
    neighbours = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
    
    %set offset of window pixels array
    window = [-1 -1; -1 0; -1 1; 0 -1; 0 0; 0 1; 1 -1; 1 0; 1 1];
        
    %for every channel in the image
    for image_channel = 1:1:image_channels
        %get the image channel separately
        img = I(:,:,image_channel);
        
        %create the channel's gray co-occurrence matrix with the closest 8
        %neighbours
        H = graycomatrix(img, 'NumLevels', gray_levels, 'Offset', neighbours);
        
        %since the function gives the co-occurrence matrix for EVERY
        %neighbour SEPARATELY, sum up all the matrices
        H = sum(H, 3);
        
        %show colormap of 2d histogram/co-ocurrence matrix
        %{
        figure, imagesc(H), colormap(jet),...
            title(['H for channel ', num2str(image_channel)])
            %Y-axis values start increasing from the bottom
            set(gca, 'YDir', 'normal')
            hold on;
        %}
        
        %homogeneity lower bound values
        h_low = zeros(1, gray_levels);
        
        %homogeneity upper bound values
        h_up = zeros(1, gray_levels);
               
        %going through the gray co-occurrence matrix
        for i = 1:1:gray_levels
            %setting threshold to pass
            threshold = 2;
            values = [];
            for j = 1:1:gray_levels
                result = 0;
                counter = 0;
                %move with a 1x3 window through the matrix
                k_values = [-1:1:1];
                for k = k_values
                    if j+k >= 1 && j+k <= 256
                        result = result + H(i, j+k);
                        counter = counter + 1;
                    end
                end
                %get the mean value
                result = result / counter;
                %if the value passed the threshold, save the index where it
                %happened
                if result >= threshold 
                    values = [values j];
                %otherwise put -1 in its' place to keep track of failures
                else
                    values = [values -1];
                end
            end
            %if for a value i there are no valid indexes, set the lower and
            %upper bound at i to itself
            if all(values == -1)
                h_up(1, i) = i;
                h_low(1, i) = i;
            %otherwise search argmax and argmin
            else
                [~, h_up(1,i)] = max(values);
                %here we replace all -1 values with +inf, so the min
                %function doesn't choose an invalid index
                values(values == -1) = Inf;
                [~, h_low(1,i)] = min(values);
            end
        end
        
        
        %plot the lower and upper bound values
        %{
        plot([1:1:gray_levels], h_low, [1:1:gray_levels], h_up), xlim([1 gray_levels]), ylim([1 gray_levels])
        %}
        
        %create padded image so we can process all the meaningful pixels
        padded_img = padarray(img, [1 1], 'symmetric');
        
        %create array where we keep track of noisy pixels locations
        %if noisy_pixels(i, j) == 1 -> noisy pixel
        %else -> not a noisy pixel
        noisy_pixels = zeros(size(padded_img));
        
        %move with a 3x3 window and a stride of 1
        for i = 2:1:size(padded_img,1)-1
            for j = 2:1:size(padded_img,2)-1
                center_value = padded_img(i, j);
                noise_counter = 0;
                for k = 1:1:size(neighbours,1)
                    neighbour_value = padded_img(i+neighbours(k, 1), j+neighbours(k,2));
                    low_value = h_low(1, center_value + 1);
                    up_value = h_up(1, center_value + 1);
                    
                    %checking if the neighbour of the center pixel
                    %of the window is in the range of homogeneity
                    if neighbour_value < low_value ||...
                            neighbour_value > up_value
                        %if it's not, then we increase the noise counter
                        noise_counter = noise_counter + 1;
                    end
                    
                end
                %if the noise counter is above a certain threshold
                if noise_counter >= (75/100) * size(neighbours, 1)
                    %the center pixel of the moving window is considered
                    %noisy
                    noisy_pixels(i, j) = 1;
                end
            end
        end
        
        %plot the appearance of noisy pixels
        %{
        figure, imagesc(noisy_pixels)
        %}
        
        %construct array for keeping track of matching blocks coordinates
        matching_blocks = zeros(size(window,1), gray_levels);
        %construct array for keeping track of frequency of pixels regarding
        %matching blocks
        freqs_matching_blocks = zeros(size(window,1), gray_levels);
        
        %construct vector for keeping track of target blocks coordinates
        target_blocks = [];
        
        %construct vector for keeping track of noisy blocks coordinates
        noisy_blocks = [];
        
        %move with a 3x3 window with a stride of 1
        for i = 2:1:size(noisy_pixels,1)-1
            for j = 2:1:size(noisy_pixels,2)-1
                noise_counter = 0;
                %count the number of noisy pixels
                for k = 1:1:size(window,1)
                    if noisy_pixels(i+window(k,1),...
                            j+window(k,2)) == 1
                        noise_counter = noise_counter + 1;
                    end
                end
                %if the number of noisy pixels is smaller than a threshold
                if noise_counter < uint8(size(window,1) / 2)
                    %then the window is a matching block
                    for k = 1:1:size(window, 1)
                        freqs_matching_blocks(k,...
                            padded_img(i+window(k,1),...
                            j+window(k,2))+1) = freqs_matching_blocks(k,...
                            padded_img(i+window(k,1),...
                            j+window(k,2))+1) + 1;
                        matching_blocks(k, padded_img(i+window(k,1),...
                            j+window(k,2))+1, freqs_matching_blocks(k,...
                            padded_img(i+window(k,1),...
                            j+window(k,2))+1)) = get_scalar_from_indexes(i, j, padded_img);
                    end
                end
                %here we put an extra condition to check as if we moved
                %with a 3x3 window and a stride of 3
                if mod(i,3) == 2 && mod(j,3) == 2
                    %if there is at least 1 noisy pixel
                    if noise_counter >= 1
                        %remember the window and its'
                        %coordinate as a target block
                        target_blocks = [target_blocks...
                            get_scalar_from_indexes(i, j, padded_img)];
                    end
                    if noise_counter >= uint8(size(window,1)/2)
                        noisy_blocks = [noisy_blocks...
                            get_scalar_from_indexes(i, j, padded_img)];
                    end
                end
            end
        end
        
        %define tolerance bounds to move with through the matching blocks
        %array
        tolerance_lower = 1;
        tolerance_step = 2;
        tolerance_upper = 9;
        
        %define thresholds
        sufficient_number_of_matching_blocks = 5;
        similarity_threshold = 3;
        
        %variable to keep track if target blocks are decreasing
        decreasing_target_blocks = 1;
          
        %increase the tolerance if needed
        for d = tolerance_lower:tolerance_step:tolerance_upper
            %while the target blocks are decreasing
            while decreasing_target_blocks == 1
                %for every target block
                for t = 1:1:size(target_blocks,2)
                    current_matching_blocks = [];
                    found_enough_blocks = 0;
                    %get its' coordinate as indexes
                    [target_row, target_col] = get_indexes_from_scalar(target_blocks(t), padded_img);
                    for k = 1:1:size(window, 1)
                        %if target pixel is not noisy
                        if noisy_pixels(target_row + window(k,1), target_col + window(k,2)) == 0
                            %get its' gray value
                            gray_value = padded_img(target_row + window(k,1), target_col + window(k,2));
                            
                            %get the tolerance-bound lower limit
                            lower_limit = gray_value-d+1;
                            if lower_limit < 1
                                lower_limit = 1;
                            end
                            
                            %get the tolerance-bound upper limit
                            upper_limit = gray_value+d+1;
                            if upper_limit > gray_levels
                                upper_limit = gray_levels;
                            end
                            
                            %get all matching blocks that have the same
                            %gray level that appears in the tolerance-bound
                            %interval
                            temp_list = matching_blocks(k, lower_limit:upper_limit, :);
                            
                            %for every possible matching block candidate
                            for i = 1:1:size(temp_list, 2)
                                for j = 1:1:size(temp_list, 3)
                                    if temp_list(1, i, j) ~= 0
                                        [matching_row, matching_col] = get_indexes_from_scalar(temp_list(1,i,j), padded_img);
                                        %check if that matching block is
                                        %similar to the target block
                                        if simil(target_row, target_col, matching_row, matching_col, padded_img, noisy_pixels, d, window) >= similarity_threshold
                                            %if it is, add it to a set
                                            current_matching_blocks = [current_matching_blocks, temp_list(1,i,j)];
                                        end
                                        %if the set reaches a minimum
                                        %length, the search can be stopped
                                        if size(current_matching_blocks, 2) >= sufficient_number_of_matching_blocks
                                            found_enough_blocks = 1;
                                            break
                                        end
                                    end
                                end
                                if found_enough_blocks == 1
                                    break
                                end
                            end
                        end
                        if found_enough_blocks == 1
                            break
                        end
                    end
                    %if the set reached the minimum length
                    if found_enough_blocks == 1
                        %for every pixel in a 3x3 window
                        for k = 1:1:size(window,1)
                            %check if the Xi target pixel is noise so it can be
                            %denoised
                            if noisy_pixels(target_row + window(k,1), target_col + window(k,2)) == 1
                                result = 0;
                                counter = 0;
                                for idx = 1:1:size(current_matching_blocks, 2)
                                    [matching_row, matching_col] = get_indexes_from_scalar(current_matching_blocks(1,idx), padded_img);
                                    %if the Xi matching pixel is not noise
                                    if noisy_pixels(matching_row + window(k,1), matching_col + window(k,2)) == 0
                                        result = result + padded_img(matching_row + window(k,1), matching_col + window(k,2));
                                        counter = counter + 1;
                                    end
                                end
                                %save the mean result of all Xi matching
                                %pixels that are not noise
                                result = result / counter;
                                %denoise the target pixels
                                if counter > 0
                                    padded_img(target_row + window(k,1), target_col + window(k,2)) = result;
                                    noisy_pixels(target_row + window(k,1), target_col + window(k,2)) = 0;
                                end
                            end
                        end
                        %check if every target pixel from a certain window
                        %has been denoised
                        everything_denoised = 1;
                        for k = 1:1:size(window,1)
                            if noisy_pixels(target_row + window(k,1), target_col + window(k,2)) == 1
                                everything_denoised = 0;
                                break
                            end
                        end
                        %if every target pixel from a certain window was
                        %denoised
                        if everything_denoised == 1
                            %transform the target block into a matching
                            %block
                            for k = 1:1:size(window,1)
                                freqs_matching_blocks(k, padded_img(target_row+window(k,1),target_col+window(k,2))+1) = freqs_matching_blocks(k, padded_img(target_row+window(k,1),target_col+window(k,2))+1) + 1;
                                matching_blocks(k, padded_img(target_row + window(k,1), target_col + window(k,2))+1, freqs_matching_blocks(k, padded_img(target_row+window(k,1),target_col+window(k,2))+1)) = target_blocks(t);
                            end
                            %remove the target block
                            target_blocks(t) = [];
                            decreasing_target_blocks = 1;
                            break
                        end
                    else
                        %if the number of target blocks is not decreasing
                        %anymore, the tolerance will be increased to check
                        %a higher range of gray values in the set of
                        %matching blocks
                        decreasing_target_blocks = 0;
                    end
                end
                %if there are no more target blocks to denoise
                if size(target_blocks,2) == 0
                    decreasing_target_blocks = 0;
                end
            end
            
            %denoising of noisy blocks
            surrounding = zeros(9, 2, 4);
            %get the offsets of every surrounding block
            surrounding(:,:,1) = [-2 -2; -2 -1; -2 0; -1 -2; -1 -1; -1 0; 0 -2; 0 -1; 0 0];
            surrounding(:,:,2) = [-2 0; -2 1; -2 2; -1 0; -1 1; -1 2; 0 0; 0 1; 0 2];
            surrounding(:,:,3) = [0 -2; 0 -1; 0 0; 1 -2; 1 -1; 1 0; 2 -2; 2 -1; 2 0];
            surrounding(:,:,4) = [0 0; 0 1; 0 2; 1 0; 1 1; 1 2; 2 0; 2 1; 2 2];
            for t = 1:1:size(noisy_blocks,2)
               [noisy_row, noisy_col] = get_indexes_from_scalar(noisy_blocks(t), padded_img);
               for k = 1:1:size(surrounding,3)
                   min_row = min(surrounding(:,1,k));
                   min_col = min(surrounding(:,2,k));
                   max_row = max(surrounding(:,1,k));
                   max_col = max(surrounding(:,2,k));
                   if noisy_row + min_row < 2 || noisy_row + max_row > size(padded_img, 1) - 1 || noisy_col + min_col < 2 || noisy_col + max_col > size(padded_img, 2) - 1
                       continue
                   end
                   noisy_counter = 0;
                   for idx = 1:1:size(surrounding(:,:,k), 1)
                       if noisy_pixels(noisy_row + surrounding(idx, 1, k), noisy_col + surrounding(idx, 2, k)) == 1
                           noisy_counter = noisy_counter + 1;
                       end
                   end
                   %if a surrounding block doesn't have enough noisy pixels
                   if noisy_counter < 5
                       offset_i = -1;
                       offset_j = -1;
                       if k == 1
                           offset_i = -1;
                           offset_j = -1;
                       elseif k == 2
                           offset_i = -1;
                           offset_j = 1;
                       elseif k == 3
                           offset_i = 1;
                           offset_j = -1;
                       elseif k == 4
                           offset_i = 1;
                           offset_j = 1;
                       end
                       %turn it into a target block to be denoised later
                       target_blocks = [target_blocks get_scalar_from_indexes(i + offset_i, j + offset_j, padded_img)];
                   end
               end
            end
        end
        %save the filtered image channel and remove the padding
        J(:,:,image_channel) = padded_img(2:size(padded_img,1)-1, 2:size(padded_img,2)-1);
    end
end

function [row, col] = get_indexes_from_scalar(scalar, fitting_array)
    row = ceil(scalar / size(fitting_array, 2));
    col = mod(scalar, size(fitting_array, 2));
end

function scalar = get_scalar_from_indexes(row, col, fitting_array)
    scalar = (row-1)*size(fitting_array, 2) + col;
end

function result = simil(T_row, T_col, M_row, M_col, padded_img,...
    noisy_pixels, tolerance, window)
    
    %similarity output result
    result = 0;
    
    for i = 1:1:size(window,1)
        prod = 1;
        
        %check if pixel in target block window is noise
        if noisy_pixels(T_row + window(i,1),...
                T_col + window(i,2)) == 1
            prod = 0;
        end
        
        %check if pixel in matching block window is noise
        if prod == 1
            if noisy_pixels(M_row + window(i,1),...
                    M_col + window(i,2)) == 1
                prod = 0;
            end
        end
        
        %check if pixels in matching and target blocks are not noise
        %and if their absolute difference is smaller than a pre-set
        %tolerance
        if prod == 1
            if ~(noisy_pixels(M_row + window(i,1),...
                    M_col + window(i,2)) == 0 &&...
                    noisy_pixels(T_row + window(i,1),...
                    T_col + window(i,2)) == 0 &&...
                    abs(padded_img( M_row + window(i,1),...
                    M_col + window(i,2) )...
                    - padded_img(T_row + window(i,1),...
                    T_col + window(i,2) )) <= tolerance)
                prod = 0;
            end
        end
        
        result = result + prod;
    end
end