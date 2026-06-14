# Question 3 (60 marks)

This code solves the two dimensional wave equation. This code **currently works**, and produces this result (Sound Pressure Contours):

![image](./Q4_Result.png)

The main function which does the computing is the Solve() function. In the solve function, a small function is used to compute the source of the sound:

```c
float Compute_Sound_Source(float x, float y, float time) {
    // See if this location has a source
    float freq = 1000.0;
    if ((x > 0.45*L) & (x < 0.55*L) & (y > 0.2*H) & (y < 0.25*H)) {
	return 1.0*sin(freq*time);
    } else {
        return 0.0;
    }
}
```


## Your mission (60 marks)

Rewrite this code (without using any AI) to use CUDA and run the computation on the GPU. This should include:

* Writing code to select a GPU to use (**5 marks**)

* Update the Allocate_Memory() and Free_Memory() functions to allocate three new variables - d_Temp_old, d_Temp and d_Temp_new - on the GPU. (**5 marks**)

* Copy the initial result (Temp) from the host to the device (d_Temp). (**5 marks**)

* Write a \_\_device\_\_ function called Compute_Sound_Source_GPU(float x, float y) to compute the sound source at x,y and time t on the GPU. (**10 marks**)

* Write a \_\_global\_\_ function called Compute_Sound_GPU(float *d_Temp_old,float *d_Temp, float *d_Tem, p_new) to compute the new temperature, (**20 marks**)

* Update the sound sources and pressure correctly as currently done in the CPU code (**10 marks**) and

* Copy the result (d_Temp) back to the CPU when complete (**5 marks**)

Your code should still save the results to file (results.txt) - this file will be loaded and checked for correctness. **Do not change the format of the results.txt file**.

You **DO NOT** need to make any graphs. It might help to check your result, however.

## Notes

This CPU code takes approximately 1 minute to run on one CPU.

Your score (50 marks) will be modified if:

* It does not make and run, or I cannot load results.txt (-50%)
* It runs, but does not produce the correct result (-25%)
* It runs, but the code is VERY BADLY written (-10%),
* It runs correctly (0%), and
* It runs correctly and faster than expected (+25%).

Ways you might get it to run faster than expected:  
* Using shared memory,
* Using an optimal number of threads per blocks.
* Meow Meow Meow Meow Meow.

Ways to write slow code, or lose marks because your code is badly written:
* Copy what the AI said to do in your tutorial assignments.

