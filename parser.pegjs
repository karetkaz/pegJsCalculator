/* Parser variable: calculator.parser
// test variables and functions
{calculator = {
	constants:{
		e: Math.E,
		pi: Math.PI,
	},
	functions:{
		sin: Math.sin,
	}
}} // */

start = lhs:expr_set? rhs:( _ ';' _ expr_set)* {
	for (var i = 0; i < rhs.length; i += 1) {
		lhs = rhs[i][3];
	}
	return lhs;
}

expr_pri
  = fun:identifyer? _ '(' _ val:expr_com? _ ')' _ { return fun ? calculator.functions[fun].apply(this, val || []) : val; }
  / val:identifyer _ { return calculator.constants[val] || calculator.variables[val]; }
  / val:integer _ { return parseInt(val); }
  / val:decimal _ { return parseFloat(val); }

expr_unr
  = '+' rhs:expr_unr { return rhs; }
  / '-' rhs:expr_unr { return -rhs; }
  / '~' rhs:expr_unr { return ~rhs; }
  / '!' rhs:expr_unr { return rhs ? 1 : 0; }
  / expr_pri

expr_mul = lhs:expr_unr op:(_('**' / '*' / '/' / '%') _ expr_unr)* {
	for (var i = 0; i < op.length; i += 1) {
		var rhs = op[i];
		switch (rhs[1]) {
			case '**': lhs = Math.pow(lhs, rhs[3]); break;
			case '*': lhs *= rhs[3]; break;
			case '/': lhs /= rhs[3]; break;
			case '%': lhs %= rhs[3]; break;
		}
	}
	return lhs;
}
expr_add = lhs:expr_mul op:(_('+' / '-') _ expr_mul)* {
	for (var i = 0; i < op.length; i += 1) {
		var rhs = op[i];
		switch (rhs[1]) {
			case '+': lhs += rhs[3]; break;
			case '-': lhs -= rhs[3]; break;
		}
	}
	return lhs;
}
expr_shr = lhs:expr_add op:(_('<<' / '>>>' / '>>') _ expr_add)* {
	for (var i = 0; i < op.length; i += 1) {
		var rhs = op[i];
		switch (rhs[1]) {
			case '<<': lhs <<= rhs[3]; break;
			case '>>': lhs >>= rhs[3]; break;
			case '>>>': lhs >>>= rhs[3]; break;
		}
	}
	return lhs;
}
expr_rel = lhs:expr_shr op:(_('<=' / '<' / '>=' / '>') _ rhs:expr_shr)* {
	for (var i = 0; i < op.length; i += 1) {
		var rhs = op[i];
		switch (rhs[1]) {
			case '<': lhs = lhs < rhs[3] ? 1 : 0; break;
			case '<=': lhs = lhs <= rhs[3] ? 1 : 0; break;
			case '>': lhs = lhs > rhs[3] ? 1 : 0; break;
			case '>=': lhs = lhs >= rhs[3] ? 1 : 0; break;
		}
	}
	return lhs;
}
expr_equ = lhs:expr_rel op:(_('==' / '!=') _ rhs:expr_rel)* {
	for (var i = 0; i < op.length; i += 1) {
		var rhs = op[i];
		switch (rhs[1]) {
			case '==': lhs = lhs == rhs[3] ? 1 : 0; break;
			case '!=': lhs = lhs != rhs[3] ? 1 : 0; break;
		}
	}
	return lhs;
}
expr_and = lhs:expr_equ op:(_ '&' _ expr_equ)* {
	for (var i = 0; i < op.length; i += 1) {
		lhs &= op[i][3];
	}
	return lhs;
}
expr_xor = lhs:expr_and op:(_ '^' _ expr_and)* {
	for (var i = 0; i < op.length; i += 1) {
		lhs ^= op[i][3];
	}
	return lhs;
}
expr_ior = lhs:expr_xor op:(_ '|' _ expr_xor)* {
	for (var i = 0; i < op.length; i += 1) {
		lhs |= op[i][3];
	}
	return lhs;
}
expr_lnd = lhs:expr_ior op:(_ '&&' _ expr_ior)* {
	for (var i = 0; lhs && i < op.length; i += 1) {
		lhs = op[i][3];
	}
	return lhs;// ? 1 : 0;
}
expr_lor = lhs:expr_lnd op:(_ '||' _ expr_lnd)* {
	for (var i = 0; !lhs && i < op.length; i += 1) {
		lhs = op[i][3];
	}
	return lhs;// ? 1 : 0;
}
expr_sel = tst:expr_lor _ '?' _ lhs:expr_sel _ ':' _ rhs:expr_sel {	// this is right to left !!!
	return tst ? lhs : rhs;
} / expr_lor
expr_set = lhs:identifyer _ op:('=' / '**=' / '*=' / '/=' / '%=' / '+=' / '-=' / '<<=' / '>>>=' / '>>=' / '&=' / '^=' / '|=') _ rhs:expr_set {	// TODO: these are right to left !!!
	switch (op) {
		case '=': calculator.variables[lhs] = rhs; break;
		case '**=': calculator.variables[lhs] = Math.pow(calculator.variables[lhs], rhs); break;
		case '*=': calculator.variables[lhs] *= rhs; break;
		case '/=': calculator.variables[lhs] /= rhs; break;
		case '%=': calculator.variables[lhs] %= rhs; break;
		case '+=': calculator.variables[lhs] += rhs; break;
		case '-=': calculator.variables[lhs] -= rhs; break;
		case '<<=': calculator.variables[lhs] <<= rhs; break;
		case '>>=': calculator.variables[lhs] >>= rhs; break;
		case '>>>=': calculator.variables[lhs] >>>= rhs; break;
		case '&=': calculator.variables[lhs] &= rhs; break;
		case '^=': calculator.variables[lhs] ^= rhs; break;
		case '|=': calculator.variables[lhs] |= rhs; break;
	}
	return lhs;
} / expr_sel
expr_com = lhs:expr_set op:( _ ',' _ expr_set)* {
	lhs = [lhs];
	for (var i = 0; i < op.length; i += 1) {
		lhs[lhs.length] = op[i][3];
	}
	return lhs;
}

integer
  = '0x' d1:[0-9a-fA-F]+ {return '0x' + d1.join(''); }
  / '0o' d1:[0-7]+ {return '0' + d1.join(''); }
  // makes problems parsing 0.0 '0' { return '0'; }

decimal
  = d1:digits d2:('.') d3:digits d4:(exp?) _ {return d1 + d2 + d3 + d4;}
  / d1:digits d2:('.') d3:(exp?) _ {return d1 + d2 + d3;}
  / d1:('.') d2:digits d3:(exp?) _ {return d1 + d2 + d3;}
  / d1:digits d2:(exp?) _ {return d1 + d2;}

exp = d1:[eE]d2:[+-]?d3:digits { return d1 + d2 + d3; }
digits = d1:[0-9]+ { return d1.join(''); }
identifyer = d1:[_a-zA-Z] chars:[_a-zA-Z0-9]* { return d1 + chars.join(''); }

_ = [\t\v\f\n\r ]* {}
