%% Creates right hand side the system A*f=b from g, F over a domain
%%   g: guidance scalar field defined over domain
%%   F: known scalar function defined outside and on the boundary of domain
%%   domain: (is,js) coordinates of square domain
function b = getRHS(g, F, is, js, type)
	r = max(is) - min(is) + 1;
	c = max(js) - min(js) + 1;
	n = r * c; % number of pixels

	% right hand side, pixels stored in row-major order
	b = zeros(n,1);

	% iterate through pixels in domain
	for i = is
		for j = js
			% Add contributes from the interior (g) and the boundary (F)
			index_i = i - is(1) + 1;
			index_j = j - js(1) + 1;
			p = (index_i-1) * c + index_j; % pixel index in domain
			val = double(0);

			% locate the domain pixel in the real pixel space
			%[i, j, index_i, index_j, p]

			%TODO: assuming domain doesn't include the real edge of the pixel array
			dgr = g(i,j) - g(i,j+1); % right
			dgl = g(i,j) - g(i,j-1); % left
			dgb = g(i,j) - g(i+1,j); % below
			dga = g(i,j) - g(i-1,j); % above

			if (strcmp(type, 'mixed'))
				dFr = F(i,j) - F(i,j+1); % right
				dFl = F(i,j) - F(i,j-1); % left
				dFb = F(i,j) - F(i+1,j); % below
				dFa = F(i,j) - F(i-1,j); % above
				if (abs(dgr) > abs(dFr)) val = val + dgr; else val = val + dFr; end
				if (abs(dgl) > abs(dFl)) val = val + dgl; else val = val + dFl; end
				if (abs(dga) > abs(dFa)) val = val + dga; else val = val + dFa; end
				if (abs(dgb) > abs(dFb)) val = val + dgb; else val = val + dFb; end
			elseif (strcmp(type, 'seamless'))
				val = dgr + dgl + dga + dgb;
			else
				error('Invalid cloning scheme, pick one of [mixed, seamless]');
			end

			% boundary contributions: for all neighbors on the
			% boundary of domain, add it's f* known value
			if (index_j == c) val = val + F(i,j+1); end % right
			if (index_j == 1) val = val + F(i,j-1); end % left
			if (index_i == r) val = val + F(i+1,j); end % below
			if (index_i == 1) val = val + F(i-1,j); end % above

			b(p) = val;
		end
	end
end
