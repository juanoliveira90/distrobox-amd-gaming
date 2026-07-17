#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {

    SDL_Window *window;                  
    SDL_Renderer *renderer;

    int selected = 0;
    int confirmed = -1;

    const int char_size = 8;

    bool done = false;

    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD);              // Initialize SDL3

    window = SDL_CreateWindow(
        "Game mode Prompt",                  
        640,                               
        480,                               
        SDL_WINDOW_OPENGL                  
    );

    if (window == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_ERROR, "Could not create window: %s\n", SDL_GetError());
        return 1;
    }
  
    renderer = SDL_CreateRenderer(window, NULL);

    while (!done) {
        SDL_Event event;

        while (SDL_PollEvent(&event)) {
            switch(event.type) {
                case SDL_EVENT_QUIT:
                    done = true;
                    break;
                
                // Keyboard
                case SDL_EVENT_KEY_DOWN:
                    if (event.key.key == SDLK_UP)       selected = 0;
                    if (event.key.key == SDLK_DOWN)     selected = 1;
                    if (event.key.key == SDLK_RETURN)   confirmed = selected;
                    break;

                // Gamepad
                case SDL_EVENT_GAMEPAD_ADDED:
                    SDL_OpenGamepad(event.gdevice.which);
                    break;
                
                case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
                    if (event.gbutton.button == SDL_GAMEPAD_BUTTON_DPAD_UP) selected = 0;
                    if (event.gbutton.button == SDL_GAMEPAD_BUTTON_DPAD_DOWN) selected = 1;
                    if (event.gbutton.button == SDL_GAMEPAD_BUTTON_SOUTH) confirmed = selected;
                    break;
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
        SDL_RenderClear(renderer);

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
        
        // Upper dialog
        char* upper_dialog_str = "Are you sure you wanna";
        char* upper_dialog_str1 = "switch to Game Mode?";
        
        int upper_x = (640/2 - strlen(upper_dialog_str) * char_size) / 2;
        int upper_y = (480/2 - strlen(upper_dialog_str) * char_size) / 2;
        
        int upper_x1 = (640/2 - strlen(upper_dialog_str1) * char_size) / 2;
        int upper_y1 = (480/2 - strlen(upper_dialog_str1) * char_size) / 2;
  
        SDL_SetRenderScale(renderer, 2.0f, 2.0f);
        SDL_RenderDebugText(renderer, upper_x, upper_y, upper_dialog_str);
        SDL_RenderDebugText(renderer, upper_x1, upper_y1, upper_dialog_str1);
        

        // Options        
        char* opt = selected == 0 ? "Yes *" : "Yes";
        char* opt1 = selected == 1 ? "No *" : "No";
    
        int middle_x = (640/2 - strlen(opt) * char_size) / 2;
        int middle_y = (480/2 - 2 * 8) / 2;

        int middle_x1 = (640/2 - strlen(opt1) * char_size) / 2;
        int middle_y1 = (480/2 - 2 * 8) / 2;
        
        SDL_RenderDebugText(renderer, middle_x, middle_y, opt);
        SDL_RenderDebugText(renderer, middle_x1, middle_y1 + 16, opt1);

     
        // Lower dialog
        char* lower_dialog_str = "This will kill the current session!";
        char* lower_dialog_str1 = "See `readme.md` for details";
    
        int lower_x = (1280/2 - strlen(lower_dialog_str) * char_size) / 2;
        int lower_y = (1600/2 - 2 * char_size) / 2;
       
        int lower_x1 = (1280/2 - strlen(lower_dialog_str1) * char_size) / 2;
        int lower_y1 = lower_y + 16;
        
        SDL_SetRenderScale(renderer, 1.0f, 1.0f);
        SDL_RenderDebugText(renderer, lower_x, lower_y, lower_dialog_str);  
        SDL_RenderDebugText(renderer, lower_x1, lower_y1, lower_dialog_str1);

        SDL_RenderPresent(renderer);
        

        if (confirmed == 0 ) { // yes
            system("sudo systemctl start gamemode.service");
            return 0;
        }
        else if (confirmed == 1) { // no
            done = true;
        } 
    }

    // Close and destroy the window
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    // Clean up
    SDL_Quit();
    return 0;
}
