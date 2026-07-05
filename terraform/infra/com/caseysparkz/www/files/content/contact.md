---
title: 'Contact'
draft: false
language: 'en'
description: 'Contact Page'

---
<!-- @format -->
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" type="text/javascript" ></script>
<script src="/js/contactForm.js" type="text/javascript"></script>
<section class="lg:pb-24">
    <div class="max-w-screen-md px-4 mx-auto">
        <p class=" mb-8 font-light text-center text-gray-500 lg:mb-16 dark:text-gray-400 sm:text-xl" >
            Want to reach out? Do it here.
        </p>
        <form name="contact" id="contact-form" class="space-y-8" method="post" >
            <div class="my-4">                                                  <!-- Sender name -->
                <input
                    type="text"
                    id="sender_name"
                    placeholder="Name"
                    name="sender_name"
                    class="shadow-sm bg-gray-50 border border-gray-300 text-gray-900 text-md rounded-lg focus:ring-indigo-500 focus:border-indigo-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-indigo-500 dark:focus:border-indigo-500 dark:shadow-sm-light"
                    required
                    >
            </div>
            <div class="my-4">                                                  <!-- Sender email address -->
                <input
                    type="email"
                    id="sender_email"
                    name="sender_email"
                    class="shadow-sm bg-gray-50 border border-gray-300 text-gray-900 text-md rounded-lg focus:ring-indigo-500 focus:border-indigo-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-indigo-500 dark:focus:border-indigo-500 dark:shadow-sm-light"
                    placeholder="Email Address"
                    required
                >
            </div>
            <div class="my-4 sm:col-span-2">                                    <!-- Email body -->
                <textarea
                    id="message"
                    name="message"
                    rows="6"
                    class="block p-2.5 w-full text-md text-gray-900 bg-gray-50 rounded-lg shadow-sm border border-gray-300 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-indigo-500 dark:focus:border-indigo-500"
                    placeholder="Message"
                    required
                    ></textarea>
                </div>
            <div class="mt-6 lg:pb-16">                                         <!-- Submit button -->
                <button
                    type="submit"
                    onClick="submitEvent(event)"
                    class="
                        px-5
                        py-3
                        font-bold
                        text-center
                        text-white
                        bg-indigo-600
                        rounded-lg
                        text-md
                        sm:w-fit
                        hover:bg-indigo-800
                        focus:ring-4
                        focus:outline-none
                        focus:ring-indigo-300
                        dark:bg-indigo-600
                        dark:hover:bg-indigo-700
                        dark:focus:ring-indigo-800
                        "
                    >
                    Send
                    </button>
                </div>
            </form>
        </div>
    </section>
