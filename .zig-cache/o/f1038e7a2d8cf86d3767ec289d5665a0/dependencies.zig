pub const packages = struct {
    pub const @"test/link" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link";
        pub const build_zig = @import("test/link");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "bss", "test/link/bss" },
            .{ "common_symbols_alignment", "test/link/common_symbols_alignment" },
            .{ "interdependent_static_c_libs", "test/link/interdependent_static_c_libs" },
            .{ "static_libs_from_object_files", "test/link/static_libs_from_object_files" },
            .{ "glibc_compat", "test/link/glibc_compat" },
            .{ "wasm_archive", "test/link/wasm/archive" },
            .{ "wasm_basic_features", "test/link/wasm/basic-features" },
            .{ "wasm_export", "test/link/wasm/export" },
            .{ "wasm_export_data", "test/link/wasm/export-data" },
            .{ "wasm_extern", "test/link/wasm/extern" },
            .{ "wasm_extern_mangle", "test/link/wasm/extern-mangle" },
            .{ "wasm_function_table", "test/link/wasm/function-table" },
            .{ "wasm_infer_features", "test/link/wasm/infer-features" },
            .{ "wasm_producers", "test/link/wasm/producers" },
            .{ "wasm_shared_memory", "test/link/wasm/shared-memory" },
            .{ "wasm_stack_pointer", "test/link/wasm/stack_pointer" },
            .{ "wasm_type", "test/link/wasm/type" },
        };
    };
    pub const @"test/link/bss" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/bss";
        pub const build_zig = @import("test/link/bss");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/common_symbols_alignment" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/common_symbols_alignment";
        pub const build_zig = @import("test/link/common_symbols_alignment");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/glibc_compat" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/glibc_compat";
        pub const build_zig = @import("test/link/glibc_compat");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/interdependent_static_c_libs" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/interdependent_static_c_libs";
        pub const build_zig = @import("test/link/interdependent_static_c_libs");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/static_libs_from_object_files" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/static_libs_from_object_files";
        pub const build_zig = @import("test/link/static_libs_from_object_files");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/archive" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/archive";
        pub const build_zig = @import("test/link/wasm/archive");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/basic-features" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/basic-features";
        pub const build_zig = @import("test/link/wasm/basic-features");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/export" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/export";
        pub const build_zig = @import("test/link/wasm/export");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/export-data" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/export-data";
        pub const build_zig = @import("test/link/wasm/export-data");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/extern" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/extern";
        pub const build_zig = @import("test/link/wasm/extern");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/extern-mangle" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/extern-mangle";
        pub const build_zig = @import("test/link/wasm/extern-mangle");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/function-table" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/function-table";
        pub const build_zig = @import("test/link/wasm/function-table");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/infer-features" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/infer-features";
        pub const build_zig = @import("test/link/wasm/infer-features");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/producers" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/producers";
        pub const build_zig = @import("test/link/wasm/producers");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/shared-memory" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/shared-memory";
        pub const build_zig = @import("test/link/wasm/shared-memory");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/stack_pointer" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/stack_pointer";
        pub const build_zig = @import("test/link/wasm/stack_pointer");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/link/wasm/type" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/link/wasm/type";
        pub const build_zig = @import("test/link/wasm/type");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone";
        pub const build_zig = @import("test/standalone");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "simple", "test/standalone/simple" },
            .{ "test_obj_link_run", "test/standalone/test_obj_link_run" },
            .{ "test_runner_path", "test/standalone/test_runner_path" },
            .{ "test_runner_module_imports", "test/standalone/test_runner_module_imports" },
            .{ "shared_library", "test/standalone/shared_library" },
            .{ "mix_o_files", "test/standalone/mix_o_files" },
            .{ "mix_c_files", "test/standalone/mix_c_files" },
            .{ "global_linkage", "test/standalone/global_linkage" },
            .{ "static_c_lib", "test/standalone/static_c_lib" },
            .{ "issue_339", "test/standalone/issue_339" },
            .{ "issue_8550", "test/standalone/issue_8550" },
            .{ "issue_794", "test/standalone/issue_794" },
            .{ "issue_5825", "test/standalone/issue_5825" },
            .{ "pkg_import", "test/standalone/pkg_import" },
            .{ "install_raw_hex", "test/standalone/install_raw_hex" },
            .{ "emit_asm_and_bin", "test/standalone/emit_asm_and_bin" },
            .{ "emit_llvm_no_bin", "test/standalone/emit_llvm_no_bin" },
            .{ "emit_asm_no_bin", "test/standalone/emit_asm_no_bin" },
            .{ "child_process", "test/standalone/child_process" },
            .{ "embed_generated_file", "test/standalone/embed_generated_file" },
            .{ "extern", "test/standalone/extern" },
            .{ "dep_diamond", "test/standalone/dep_diamond" },
            .{ "dep_triangle", "test/standalone/dep_triangle" },
            .{ "dep_recursive", "test/standalone/dep_recursive" },
            .{ "dep_mutually_recursive", "test/standalone/dep_mutually_recursive" },
            .{ "dep_shared_builtin", "test/standalone/dep_shared_builtin" },
            .{ "dep_lazypath", "test/standalone/dep_lazypath" },
            .{ "dirname", "test/standalone/dirname" },
            .{ "dep_duplicate_module", "test/standalone/dep_duplicate_module" },
            .{ "empty_env", "test/standalone/empty_env" },
            .{ "env_vars", "test/standalone/env_vars" },
            .{ "issue_11595", "test/standalone/issue_11595" },
            .{ "libcxx", "test/standalone/libcxx" },
            .{ "libfuzzer", "test/standalone/libfuzzer" },
            .{ "load_dynamic_library", "test/standalone/load_dynamic_library" },
            .{ "windows_resources", "test/standalone/windows_resources" },
            .{ "windows_entry_points", "test/standalone/windows_entry_points" },
            .{ "windows_spawn", "test/standalone/windows_spawn" },
            .{ "windows_argv", "test/standalone/windows_argv" },
            .{ "windows_bat_args", "test/standalone/windows_bat_args" },
            .{ "self_exe_symlink", "test/standalone/self_exe_symlink" },
            .{ "c_compiler", "test/standalone/c_compiler" },
            .{ "c_embed_path", "test/standalone/c_embed_path" },
            .{ "issue_12706", "test/standalone/issue_12706" },
            .{ "strip_empty_loop", "test/standalone/strip_empty_loop" },
            .{ "strip_struct_init", "test/standalone/strip_struct_init" },
            .{ "cmakedefine", "test/standalone/cmakedefine" },
            .{ "zerolength_check", "test/standalone/zerolength_check" },
            .{ "stack_iterator", "test/standalone/stack_iterator" },
            .{ "coff_dwarf", "test/standalone/coff_dwarf" },
            .{ "compiler_rt_panic", "test/standalone/compiler_rt_panic" },
            .{ "ios", "test/standalone/ios" },
            .{ "depend_on_main_mod", "test/standalone/depend_on_main_mod" },
            .{ "install_headers", "test/standalone/install_headers" },
            .{ "dependency_options", "test/standalone/dependency_options" },
            .{ "dependencyFromBuildZig", "test/standalone/dependencyFromBuildZig" },
            .{ "run_output_paths", "test/standalone/run_output_paths" },
            .{ "run_output_caching", "test/standalone/run_output_caching" },
            .{ "empty_global_error_set", "test/standalone/empty_global_error_set" },
            .{ "omit_cfi", "test/standalone/omit_cfi" },
            .{ "config_header", "test/standalone/config_header" },
            .{ "entry_point", "test/standalone/entry_point" },
            .{ "run_cwd", "test/standalone/run_cwd" },
            .{ "tsan", "test/standalone/tsan" },
        };
    };
    pub const @"test/standalone/c_compiler" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/c_compiler";
        pub const build_zig = @import("test/standalone/c_compiler");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/c_embed_path" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/c_embed_path";
        pub const build_zig = @import("test/standalone/c_embed_path");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/child_process" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/child_process";
        pub const build_zig = @import("test/standalone/child_process");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/cmakedefine" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/cmakedefine";
        pub const build_zig = @import("test/standalone/cmakedefine");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/coff_dwarf" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/coff_dwarf";
        pub const build_zig = @import("test/standalone/coff_dwarf");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/compiler_rt_panic" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/compiler_rt_panic";
        pub const build_zig = @import("test/standalone/compiler_rt_panic");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/config_header" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/config_header";
        pub const build_zig = @import("test/standalone/config_header");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dep_diamond" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dep_diamond";
        pub const build_zig = @import("test/standalone/dep_diamond");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dep_duplicate_module" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dep_duplicate_module";
        pub const build_zig = @import("test/standalone/dep_duplicate_module");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dep_lazypath" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dep_lazypath";
        pub const build_zig = @import("test/standalone/dep_lazypath");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dep_mutually_recursive" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dep_mutually_recursive";
        pub const build_zig = @import("test/standalone/dep_mutually_recursive");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dep_recursive" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dep_recursive";
        pub const build_zig = @import("test/standalone/dep_recursive");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dep_shared_builtin" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dep_shared_builtin";
        pub const build_zig = @import("test/standalone/dep_shared_builtin");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dep_triangle" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dep_triangle";
        pub const build_zig = @import("test/standalone/dep_triangle");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/depend_on_main_mod" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/depend_on_main_mod";
        pub const build_zig = @import("test/standalone/depend_on_main_mod");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/dependencyFromBuildZig" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dependencyFromBuildZig";
        pub const build_zig = @import("test/standalone/dependencyFromBuildZig");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "other", "test/standalone/dependencyFromBuildZig/other" },
        };
    };
    pub const @"test/standalone/dependencyFromBuildZig/other" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dependencyFromBuildZig/other";
        pub const build_zig = @import("test/standalone/dependencyFromBuildZig/other");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"test/standalone/dependency_options" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dependency_options";
        pub const build_zig = @import("test/standalone/dependency_options");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "other", "test/standalone/dependency_options/other" },
        };
    };
    pub const @"test/standalone/dependency_options/other" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dependency_options/other";
        pub const build_zig = @import("test/standalone/dependency_options/other");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"test/standalone/dirname" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/dirname";
        pub const build_zig = @import("test/standalone/dirname");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/embed_generated_file" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/embed_generated_file";
        pub const build_zig = @import("test/standalone/embed_generated_file");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/emit_asm_and_bin" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/emit_asm_and_bin";
        pub const build_zig = @import("test/standalone/emit_asm_and_bin");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/emit_asm_no_bin" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/emit_asm_no_bin";
        pub const build_zig = @import("test/standalone/emit_asm_no_bin");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/emit_llvm_no_bin" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/emit_llvm_no_bin";
        pub const build_zig = @import("test/standalone/emit_llvm_no_bin");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/empty_env" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/empty_env";
        pub const build_zig = @import("test/standalone/empty_env");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/empty_global_error_set" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/empty_global_error_set";
        pub const build_zig = @import("test/standalone/empty_global_error_set");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/entry_point" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/entry_point";
        pub const build_zig = @import("test/standalone/entry_point");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/env_vars" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/env_vars";
        pub const build_zig = @import("test/standalone/env_vars");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/extern" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/extern";
        pub const build_zig = @import("test/standalone/extern");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/global_linkage" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/global_linkage";
        pub const build_zig = @import("test/standalone/global_linkage");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/install_headers" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/install_headers";
        pub const build_zig = @import("test/standalone/install_headers");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/install_raw_hex" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/install_raw_hex";
        pub const build_zig = @import("test/standalone/install_raw_hex");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/ios" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/ios";
        pub const build_zig = @import("test/standalone/ios");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/issue_11595" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/issue_11595";
        pub const build_zig = @import("test/standalone/issue_11595");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/issue_12706" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/issue_12706";
        pub const build_zig = @import("test/standalone/issue_12706");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/issue_339" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/issue_339";
        pub const build_zig = @import("test/standalone/issue_339");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/issue_5825" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/issue_5825";
        pub const build_zig = @import("test/standalone/issue_5825");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/issue_794" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/issue_794";
        pub const build_zig = @import("test/standalone/issue_794");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/issue_8550" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/issue_8550";
        pub const build_zig = @import("test/standalone/issue_8550");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/libcxx" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/libcxx";
        pub const build_zig = @import("test/standalone/libcxx");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/libfuzzer" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/libfuzzer";
        pub const build_zig = @import("test/standalone/libfuzzer");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/load_dynamic_library" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/load_dynamic_library";
        pub const build_zig = @import("test/standalone/load_dynamic_library");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/mix_c_files" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/mix_c_files";
        pub const build_zig = @import("test/standalone/mix_c_files");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/mix_o_files" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/mix_o_files";
        pub const build_zig = @import("test/standalone/mix_o_files");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/omit_cfi" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/omit_cfi";
        pub const build_zig = @import("test/standalone/omit_cfi");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/pkg_import" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/pkg_import";
        pub const build_zig = @import("test/standalone/pkg_import");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/run_cwd" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/run_cwd";
        pub const build_zig = @import("test/standalone/run_cwd");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/run_output_caching" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/run_output_caching";
        pub const build_zig = @import("test/standalone/run_output_caching");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/run_output_paths" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/run_output_paths";
        pub const build_zig = @import("test/standalone/run_output_paths");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/self_exe_symlink" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/self_exe_symlink";
        pub const build_zig = @import("test/standalone/self_exe_symlink");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/shared_library" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/shared_library";
        pub const build_zig = @import("test/standalone/shared_library");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/simple" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/simple";
        pub const build_zig = @import("test/standalone/simple");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/stack_iterator" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/stack_iterator";
        pub const build_zig = @import("test/standalone/stack_iterator");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/static_c_lib" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/static_c_lib";
        pub const build_zig = @import("test/standalone/static_c_lib");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/strip_empty_loop" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/strip_empty_loop";
        pub const build_zig = @import("test/standalone/strip_empty_loop");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/strip_struct_init" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/strip_struct_init";
        pub const build_zig = @import("test/standalone/strip_struct_init");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/test_obj_link_run" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/test_obj_link_run";
        pub const build_zig = @import("test/standalone/test_obj_link_run");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/test_runner_module_imports" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/test_runner_module_imports";
        pub const build_zig = @import("test/standalone/test_runner_module_imports");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/test_runner_path" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/test_runner_path";
        pub const build_zig = @import("test/standalone/test_runner_path");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/tsan" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/tsan";
        pub const build_zig = @import("test/standalone/tsan");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/windows_argv" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/windows_argv";
        pub const build_zig = @import("test/standalone/windows_argv");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/windows_bat_args" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/windows_bat_args";
        pub const build_zig = @import("test/standalone/windows_bat_args");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/windows_entry_points" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/windows_entry_points";
        pub const build_zig = @import("test/standalone/windows_entry_points");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/windows_resources" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/windows_resources";
        pub const build_zig = @import("test/standalone/windows_resources");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/windows_spawn" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/windows_spawn";
        pub const build_zig = @import("test/standalone/windows_spawn");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"test/standalone/zerolength_check" = struct {
        pub const build_root = "/Users/rachpradhan/zag/test/standalone/zerolength_check";
        pub const build_zig = @import("test/standalone/zerolength_check");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "standalone_test_cases", "test/standalone" },
    .{ "link_test_cases", "test/link" },
};
