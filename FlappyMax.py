# A flappybird clone, for my son.

import pygame
import sys
import random

# Game settings
screen_width = 1000
screen_height = screen_width  # Flappiness!

background_color = (50, 150, 250)  # Light blue
hspeed = 3  # Speed of the bird
obstacle_interval = 1800
score_size = 122
gap_size = 400

class Bird(pygame.sprite.Sprite):
    def __init__(self, x, y, font=None):
        super().__init__()
        self.image = pygame.Surface((100, 100))  # Bird shape
        self.image.fill((255, 255, 255))  # Change bird color to white
        self.rect = self.image.get_rect(center=(screen_width // 2, screen_height // 2))  # Center bird
        self.velocity = -5  # Initial velocity
        self.font = font

    def move_upwards(self):
        self.velocity = -5  # Adjust this value to control the movement speed

    def update(self):
        self.velocity += 0.2  # Simulate gravity
        self.rect.y += self.velocity  # Update position based on velocity
        
        # Prevent the bird from going off-screen
        if self.rect.top <= -100:
            self.rect.top = -100
        elif self.rect.bottom >= screen_height:
            self.rect.bottom = screen_height
            self.velocity = -self.velocity * 0.75  # Reset velocity when hitting the ground

    def draw(self, screen):
        # Original drawing code
        screen.blit(self.image, self.rect)

        # New debug info drawing code
        if self.font:
            debug_info = f"Pos: ({self.rect.x}, {self.rect.y}), Vel: {self.velocity:.1f}"
            debug_surf = self.font.render(debug_info, True, (255, 255, 255))  # White text
            screen.blit(debug_surf, (self.rect.x, self.rect.y - 20))  # Position above the bird

class Obstacle(pygame.sprite.Sprite):
    def __init__(self, x, gap_size, height_range=(100, 500), width=100, font=None):
        super().__init__()
        self.font = font
        self.gap_size = gap_size
        self.top_height = random.randint(*height_range)
        self.bottom_height = screen_height - self.top_height - gap_size
        self.scored = False
        
        # Create the top rectangle
        self.top_image = pygame.Surface((width, self.top_height))
        self.top_image.fill((255, 255, 255))
        self.top_rect = self.top_image.get_rect(topleft=(x, 0))
        
        # Create the bottom rectangle
        self.bottom_image = pygame.Surface((width, self.bottom_height))
        self.bottom_image.fill((255, 255, 255))
        self.bottom_rect = self.bottom_image.get_rect(topleft=(x, screen_height - self.bottom_height))
        
    def update(self):
        self.top_rect.x -= hspeed  # Move left
        self.bottom_rect.x -= hspeed  # Move left
        
        # Check if the obstacle is completely off the screen
        if self.top_rect.right < 0:
            self.kill()  # Remove this obstacle from any sprite groups
    
    def draw(self, screen):
        screen.blit(self.top_image, self.top_rect)
        screen.blit(self.bottom_image, self.bottom_rect)

        # Render and draw debug info if a font is available
        if self.font:
            debug_info = f"Top: {self.top_height}, Bottom: {self.bottom_height}, Gap: {self.gap_size}"
            debug_surf = self.font.render(debug_info, True, (255, 255, 255))  # White text
            screen.blit(debug_surf, (self.top_rect.x, self.top_rect.bottom + 5))  # Adjust position as needed
 
def game_over_screen(screen):
    font = pygame.font.Font(None, 74)
    text = font.render("Game Over", True, (255, 0, 0))
    screen.blit(text, (screen_width // 2 - text.get_width() // 2, screen_height // 2 - text.get_height() // 2))
    pygame.display.flip()
    pygame.time.wait(2000)  # Display the game over text for 2 seconds

def main():
    pygame.init()
    screen = pygame.display.set_mode((screen_width, screen_height))
    pygame.display.set_caption("FlappyMax")

    debug_font = pygame.font.Font(None, 24) 

    bird_group = pygame.sprite.GroupSingle()
    bird = Bird(screen_width // 2, screen_height // 2, font=debug_font)

    bird_group.add(bird)

    obstacles = pygame.sprite.Group()
    obstacle_timer = pygame.USEREVENT + 1
    pygame.time.set_timer(obstacle_timer, obstacle_interval)  # Adjust the timing as needed

    running = True
    clock = pygame.time.Clock()
    score = 0
    font = pygame.font.Font(None, score_size)

    while running:
        clock.tick(60)
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_SPACE:
                    bird.move_upwards()
            elif event.type == obstacle_timer:
                obstacles.add(Obstacle(screen_width, gap_size, font=debug_font)) 

        collision = False
        for obstacle in obstacles:
            obstacle.update()
            if obstacle.top_rect.right < bird.rect.left and not obstacle.scored:
                score += 1
                obstacle.scored = True

            if bird.rect.colliderect(obstacle.top_rect) or bird.rect.colliderect(obstacle.bottom_rect):
                collision = True
                break

            if obstacle.top_rect.right < 0 or obstacle.bottom_rect.right < 0 :
                obstacles.remove(obstacle)

        if collision:
            game_over_screen(screen)
            bird_group.empty()
            obstacles.empty()

            # Reset the obstacle generation timer
            pygame.time.set_timer(obstacle_timer, 0)  # Stop the timer
            pygame.time.set_timer(obstacle_timer, obstacle_interval)  # Restart the timer with the original interval

            bird = Bird(screen_width // 2, screen_height // 2, font=debug_font)
            bird_group.add(bird)
            score = 0  # Reset score
                
        screen.fill(background_color)
        for obstacle in obstacles:
            obstacle.draw(screen)
        
        bird_group.update()
        # bird_group.draw(screen)
        for bird in bird_group:
            bird.draw(screen)  # This calls your custom draw method that includes debug info
        
        # Display the score
        score_text = font.render(str(score), True, (255, 255, 255))
        screen.blit(score_text, (screen_width // 2 - score_text.get_width() // 2, 20))
        
        pygame.display.flip()

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
 
 
