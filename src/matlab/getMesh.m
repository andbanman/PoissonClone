function [A b] = getMesh(is, js)
	r = max(is) - min(is) + 1;
	c = max(js) - min(js) + 1;
	n = r * c; % number of pixels

	%TODO: the neighbor count extends beyond boundary, assume all interior pixels
	%N = getNeighborCounts(r,c); % pixel grid neighbor counts
	N = ones(n,1) * 4;

	% Diagonals
	d0 = reshape(N, 1, []); % neighbor count for each pixel flattened
	d1 = ones(r*c-1, 1) * -1;
	d1(c:c:end) = 0; % pixel at end of row not connected to next pixel
	dc = ones(r*c-c, 1) * -1;

	% Sparse matrix constructed from diagonals
	D = [ [dc; zeros(c,1)], [d1; 0], d0', [0; d1], [zeros(c,1); dc]  ];
	d = [-c; -1; 0; 1; c];
	A = spdiags(D,d,n,n);
end
