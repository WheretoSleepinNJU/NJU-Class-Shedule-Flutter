# Deadliner Glass source closure

Source: /Users/aritxonly/Codes/Android/Deadliner, base 967b7da573fdfa537b45900755ec630640d2cf80. The source checkout had local modifications; source-sha256.json records exact upstream inputs. MIT license retained in LICENSE.

Package names are mechanically changed. The selected Deadliner optics, shader order, feedback, progressive material and shadow recipes are preserved. Local patch: remove the optional official miuix-glass renderer, its preference and alternative shadow branch; retain semantic GlassSurfaceRole in GlassMaterialSpec.kt. No miuix-glass module is vendored or compiled. LOCAL_SHA256.json records shipped source files after these explicit patches.

Target: Kotlin/Compose compiler 2.4.10; Compose UI/Foundation 1.12.0; Material3 1.5.0-alpha08 (semantic theme bridge); MIUIX UI/Blur/Icons 0.9.4-rc01; Shapes 1.2.0. MIUIX core/blur remain required rendering dependencies for Deadliner Glass.

One Flutter TextureView is registered in one shared LayerBackdrop. Native chrome stays outside its source. Unsupported/custom layouts are handled by AdaptiveUI's original-component renderer.
