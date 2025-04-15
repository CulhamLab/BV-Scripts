function [cmap] = make_cmap(number_colours,n)
arguments
    number_colours {mustBeMember(number_colours,[2,3])} = 3
    n {mustBeNumeric} = 100;
end

cp = [0.8 0.1 0.1];
c0 = [0.5 0.5 0.5];
cn = [0.1 0.1 0.8];

switch number_colours
    case 2
        if n==1
            cmap = [c0; cp];
        else
            cmap = cell2mat(arrayfun(@(a,b) linspace(a,b,n*2)', c0, cp, 'UniformOutput', false));
        end
    case 3
        if n==1
            cmap = [cn; c0; cp];
        else
            cmap = [cell2mat(arrayfun(@(a,b) linspace(a,b,n)', cn, c0, 'UniformOutput', false));
                    cell2mat(arrayfun(@(a,b) linspace(a,b,n)', c0, cp, 'UniformOutput', false))];
        end
    otherwise
        error
end