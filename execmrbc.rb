require 'tempfile'

def optional_code(cnt)
   code = <<EOB
static int32_t idx_code#{cnt} = 0;
mrb_value return_value#{cnt};
if (idx_code#{cnt} == 0) {
	idx_code#{cnt} = mrb_read_irep(mrb, code#{cnt});
	if (idx_code#{cnt} < 0) {
		// irep_error(mrb, idx_code#{cnt});
		return -1;
	}
}
if (idx_code#{cnt} > 0) {
	int ai = mrb_gc_arena_save(mrb);
	return_value#{cnt} =  mrb_run(mrb, mrb_proc_new(mrb, mrb->irep[idx_code#{cnt}]),mrb_top_self(mrb));
	mrb_gc_arena_restore(mrb, ai);
}
EOB
  code
end


def main
  if ARGV.size != 3
    abort "usage: ruby execmrbc.rb  <original C file>  <converted C file>  <mrbc path>"
  end
  rfname = ARGV[0]
  wfname = ARGV[1]
  mrbcpath = ARGV[2]
  cnt = 0

  ## read c file all at once.
  rfile = File.read(rfname)

  ## replace ruby script in <ruby-> ... <-ruby>
  rfile.gsub!(/^([^\r\n]*)<ruby->(.*?)<-ruby>([^\r\n]*)/m) do
    rubycode = $2.strip
    tmpfile = Tempfile.new('temp.rb')
    tmpfile.write(rubycode)
    tmpfile.close
    str = `#{mrbcpath} -Bcode#{cnt} -o- #{tmpfile.path}`
    tmpfile.unlink
    str += optional_code(cnt)
    cnt += 1
    str
  end

  ## replace ruby file in <rubyfile-> ... <-rubyfile>
  rfile.gsub!(/^([^\r\n]*)<rubyfile->(.*?)<-rubyfile>([^\r\n]*)/m) do
    fname = $2.split.last.strip
    str = `#{mrbcpath} -Bcode#{cnt} -o- #{fname}`
    str += optional_code(cnt)
    cnt += 1
    str
  end

  ## write converted code
  File.open(wfname, "wb") do |w|
    w.write rfile
  end
end

main
