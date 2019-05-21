%% Clone the source image (less the 1-pixel border) into location (i0,j0) of
%% destination image
function [time n] = clone(source, destination, i0, j0, type, outFile)
	% Load images
	srcRGB = loadImage(source);
	dstRGB = loadImage(destination);

	% Define the domain
	is = [2:size(srcRGB, 1)-1];
	js = [2:size(srcRGB, 2)-1];
	n = length(is)*length(js); disp('Number of pixels:'); disp(n);

	% known scalar function f*
	F_R = dstRGB(:,:,1);
	F_G = dstRGB(:,:,2);
	F_B = dstRGB(:,:,3);

	% scalar function g, defined over domain intior
	g_R = srcRGB(:,:,1);
	g_G = srcRGB(:,:,2);
	g_B = srcRGB(:,:,3);

	% Create system of equations for each color channel
	A = getMesh(is, js);
	b_R = getRHS(g_R, F_R(i0:end,j0:end), is, js, type);
	b_G = getRHS(g_G, F_G(i0:end,j0:end), is, js, type);
	b_B = getRHS(g_B, F_B(i0:end,j0:end), is, js, type);

	% Solve for intpolated colors using Cholesky factorization
	% 1. Cholesky factorization with automatic permutation (via amd)
	t0 = cputime;
	disp('Cholesky factorization'); ts = cputime;
	[R flag p] = chol(A, 'vector');
	assert(flag == 0, 'Factorization failed');
	tf = cputime; disp(tf-ts);

	% 2. Solve with Cholesky factor and permutation vector
	disp('Solving R'); f_R = solveCholReshape(A, R, p, b_R, is, js);
	disp('Solving G'); f_G = solveCholReshape(A, R, p, b_G, is, js);
	disp('Solving B'); f_B = solveCholReshape(A, R, p, b_B, is, js);
	tf = cputime; disp('Total time:'); time = tf-t0

	% Paste intpolation into dstination
	intRGB = cat(3,f_R,f_G,f_B);
	outRGB = dstRGB;
	outRGB(is+i0,js+j0,:) = intRGB;

	if (strcmp(outFile, ''))
		% Display images back
		disp('Destination');       image(dstRGB);          pause();
		disp('Source');            image(srcRGB);          pause();
		%disp('Crop');             image(srcRGB(is,js,:)); pause();
		disp('Interpolated crop'); image(intRGB);          pause();
		disp('Final composite');   image(outRGB)
	else
		% Write out
		imwrite(dstRGB, strcat(outFile, '_dst.jpg'));
		imwrite(srcRGB, strcat(outFile, '_src.jpg'));
		imwrite(outRGB, strcat(outFile, '_out.jpg'));
		imwrite(intRGB, strcat(outFile, '_int.jpg'));
	end
end

%% Solve the system A*f=b where A(p,p) = R'*R
%% Reshape f to the original pixel ordering and dimensions
function f = solveCholReshape(A, R, p, b, is, js)
	ts = cputime;
	pt(p) = 1:length(p);
	f = R \ (R' \ b(p));
	tf = cputime;
	disp(tf-ts);
	f = f(pt); %undo permuation
	f = reshape(f, length(js), length(is))';
end

%% Load JPG image file and convert to double over [0.0,1.0]
%% TODO: must be .jpg
function A = loadImage(filename)
	A = double(imread(filename)) / 255;
end
